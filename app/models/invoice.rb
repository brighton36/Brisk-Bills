class Invoice < ActiveRecord::Base
  include ExtensibleObjectHelper
  
  # NOTE: this has to be above the has_many, otherwise activities would get nullified before this callback had a chance to return fals
  before_destroy :ensure_not_published_on_destroy
  before_destroy :ensure_were_the_most_recent

  before_update :ensure_not_published_on_update

  after_create :reattach_activities
  after_update :reattach_activities

  after_update  :mark_invoice_payments
  after_create  :mark_invoice_payments
  after_destroy :remove_invoice_payments

  belongs_to :client
  has_many :activities, :dependent => :nullify
  has_many :payments, :through => 'invoice_payments'
  
  has_and_belongs_to_many(
    :activity_types, 
    :join_table     => 'invoices_activity_types', 
    :before_remove  => :invalid_if_published, 
    :before_add     => :invalid_if_published,
    :uniq => true
  )
  
  validates_presence_of :client_id, :issued_on

  # This just ends up being useful in a couple places
  ACTIVITY_TOTAL_SQL = '(IF(activities.cost_in_cents IS NULL, 0, activities.cost_in_cents)+IF(activities.tax_in_cents IS NULL, 0, activities.tax_in_cents))'

  def initialize(*args)
    super(*args)
    end_of_last_month = Time.utc(*Time.now.to_a).last_month.end_of_month
    self.issued_on = end_of_last_month unless self.issued_on
  end
    
  def invalid_if_published(collection_record = nil)
    raise "Can't adjust an already-published invoice." if !new_record? and is_published
  end
  
  def reattach_activities
    included_activity_types = activity_types.collect{ |a| a.label.downcase }
    unincluded_activity_types = ActivityType.find(:all).collect{ |a| a.label.downcase } - included_activity_types

    # First we NULL'ify (remove) existing attachments that no longer should be:
    nullify_conditions = []
    nullify_parameters = [] 
        
    # Conditions for occurance adjutments
    nullify_conditions << '(DATEDIFF(occurred_on, DATE(?)) > 0)'
    nullify_parameters << issued_on
    
    # For the ActivityType Adjustments:
    unless unincluded_activity_types.empty?
      nullify_conditions << '(%s)' % ( ['activity_type = ?'] * unincluded_activity_types.size).join(' OR ')
      nullify_parameters += unincluded_activity_types
    end

    Activity.update_all( 
      'invoice_id = NULL', 
      [ ['invoice_id = ?', 'is_published = ?', ('(%s)' % nullify_conditions.join(' OR ')) ].join(' AND ') ]+
      [id, true]+nullify_parameters
    ) unless new_record?
    
    # Now we attach the new records :
    update_where = [
      ['invoice_id IS NULL'],
      ['is_published = ?', true],
      ['client_id = ?', client_id],
      ['DATEDIFF(occurred_on, DATE(?)) <= 0', issued_on],
      
      # Slightly more complicated, for the type includes:
      ( (included_activity_types.size > 0) ? 
        [ '('+(['activity_type = ?'] * included_activity_types.size).join(' OR ')+')', included_activity_types ] :
        [ 'activity_type IS NULL' ] )
    ]
    
    Activity.update_all(
      ['invoice_id = ?', id ],
      # This is what ActiveRecord actually expects...
      update_where.collect{|c| c[0]}.join(' AND ').to_a + update_where.reject{|c| c.length < 2 }.collect{|c| c[1]}.flatten
    )
  end
  
  def is_most_recent_invoice?
    newest_invoice = Invoice.find :first, :select => 'id', :order => 'issued_on DESC', :conditions => ['client_id = ?', client_id]

    (newest_invoice.nil? or newest_invoice.id == id) ? true : false
  end
  
  def ensure_were_the_most_recent
    unless is_most_recent_invoice?
      errors.add_to_base "Can't destroy an invoice if its not the client's most recent invoice"
      return false
    end
  end
  
  def ensure_not_published_on_destroy
    if is_published and !changes.has_key? :is_published
      errors.add_to_base "Can't destroy a published invoice"
      return false
    end
  end
  
  def ensure_not_published_on_update
    errors.add_to_base "Can't update a published invoice" if is_published and !changes.has_key? :is_published
  end
  
  def validate_on_update
    errors.add :client, "can't be updated after creation" if changes.has_key? "client_id"

    errors.add_to_base(
      "Invoice can't be updated once published."
    ) if is_published and changes.reject{|k,v| k == 'is_published'}.length > 0

    errors.add_to_base(
      "Invoice can't be unpublished, unless its the newest invoice in the client's queue."
    ) if changes.has_key?('is_published') and is_published_was and !is_most_recent_invoice?
  end

  def taxes_total
    process_total :taxes_total, :tax_in_cents
  end

  def sub_total
    process_total :sub_total, :cost_in_cents
  end
  
  def amount
    process_total :amount, ACTIVITY_TOTAL_SQL
  end
  
  def grand_total
    process_total :grand_total, ACTIVITY_TOTAL_SQL
  end
  
  def name  
    '"%s" Invoice on %s'  % [ (client) ? client.company_name : '(Unknown Client)', issued_on.strftime("%m/%d/%Y %I:%M %p") ]
  end
  
  def long_name
    "Invoice #%d (%s) - %s (%s)" % [
      id,
      issued_on.strftime("%m/%d/%Y %I:%M %p"),
      client.company_name,
      ('$%.2f' % amount.to_s).gsub(/(\d)(?=\d{3}+(\.\d*)?$)/, '\1,')
    ]
  end

  def remove_invoice_payments
    InvoicePayment.destroy_all ['invoice_id = ?', id]    
  end
  
  def mark_invoice_payments   
    if changes.has_key? "is_published"
      remove_invoice_payments
      
      if is_published
        unallocated_payments = Payment.find_with_totals( 
          :all, 
          :conditions => [
            'client_id = ? AND (payments.amount_in_cents - IF(payments_total.amount_allocated_in_cents IS NULL, 0, payments_total.amount_allocated_in_cents) ) > ?', 
            client_id, 
            0
          ] 
        )
    
        current_client_balance = 0.0.to_money
        unallocated_payments.each { |pmnt| current_client_balance -= pmnt.amount_unallocated }
        
        invoice_balance = amount
    
        unallocated_payments.each do |unallocated_pmnt|
          break if invoice_balance == 0 or current_client_balance >= 0
          
          payment_allocation = (unallocated_pmnt.amount_unallocated > invoice_balance) ?
            invoice_balance :
            unallocated_pmnt.amount_unallocated
          
          InvoicePayment.create! :invoice => self, :payment => unallocated_pmnt, :amount => payment_allocation
          
          invoice_balance -= payment_allocation
          current_client_balance += payment_allocation
        end        
      end
    end
    
  end
  
  def paid_on
    raise StandardError unless is_paid?

    InvoicePayment.find(
      :first,
      :order => 'payments.paid_on DESC', 
      :include => [:payment],
      :conditions => ['invoice_id = ?', id]
    ).payment.paid_on
    
    rescue
      nil
  end
  
  def is_paid?
    amount_outstanding.zero?
  end
  
  def amount_paid
    Money.new InvoicePayment.sum( :amount_in_cents, :conditions => ['invoice_id = ?', id] ).to_i
  end
  
  def amount_outstanding
    amount - amount_paid
  end

  def self.find_with_totals( how_many = :all, options = {} )
    joins = []
    joins << 'LEFT JOIN ('+
      "SELECT invoices.id AS invoice_id, SUM(#{ACTIVITY_TOTAL_SQL}) AS total_in_cents"+
      ' FROM invoices'+
      ' LEFT JOIN activities ON activities.invoice_id = invoices.id'+
      ' GROUP BY invoices.id'+
    ') AS activities_total ON activities_total.invoice_id = invoices.id'
    
    joins << 'LEFT JOIN ('+
      'SELECT invoices.id AS invoice_id, SUM(invoice_payments.amount_in_cents) AS total_in_cents'+
      ' FROM invoices'+
      ' LEFT JOIN invoice_payments ON invoice_payments.invoice_id = invoices.id'+
      ' GROUP BY invoices.id'+
    ') AS invoices_total ON invoices_total.invoice_id = invoices.id'

    cast_amount = 'IF(activities_total.total_in_cents IS NULL, 0,activities_total.total_in_cents)'
    cast_amount_paid = 'IF(invoices_total.total_in_cents IS NULL, 0,invoices_total.total_in_cents)'

    Invoice.find( 
      how_many,
      {
        :select => [
          'invoices.id',
          'invoices.client_id',
          'invoices.comments',
          'invoices.issued_on',
          "#{cast_amount} AS amount_in_cents",
          "#{cast_amount_paid} AS amount_paid_in_cents",
          "#{cast_amount} - #{cast_amount_paid} AS amount_outstanding_in_cents"
        ].join(', '),
        :order => 'issued_on ASC',
        :joins => joins.join(' ')
      }.merge(options)
    )
  end

  def authorized_for?(options)
    case options[:action].to_s
      when /^(update|destroy)$/
        (is_published and !is_most_recent_invoice?) ? false : true
      else
        true
    end
  end

  private 
  
  def process_total(name, field_sql)   
    Money.new Activity.sum(field_sql, :conditions => ['invoice_id = ?', id]).to_i
    
  end

  handle_extensions
end
