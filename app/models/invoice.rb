class Invoice < ActiveRecord::Base
  include ExtensibleObjectHelper
  
  # NOTE: this has to be above the has_many, otherwise activities would get nullified before this callback had a chance to return fals
  before_destroy :ensure_not_published_on_destroy
  before_destroy :ensure_were_the_most_recent

  before_update :ensure_not_published_on_update
  
  before_save :clear_invoice_payments_if_unpublished

  belongs_to :client
  has_many :activities, :dependent => :nullify
  has_many :payments, :through => :assigned_payments
  has_many :payment_assignments, :class_name => 'InvoicePayment', :dependent => :delete_all
  
  has_and_belongs_to_many(
    :activity_types, 
    :join_table     => 'invoices_activity_types', 
    :before_remove  => :invalid_if_published, 
    :before_add     => :invalid_if_published,
    :uniq => true
  )
  
  validates_presence_of :client_id, :issued_on
  
  validate :validate_invoice_payments_not_greater_than_amount

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

  def validate_invoice_payments_not_greater_than_amount
    errors.add :payment_assignments, "total is greater than invoice amount" if self.payment_assignments.inject(Money.new(0)){|sum,ip| ip.amount+sum } > self.amount
  end

  def taxes_total
    process_total :taxes_total, :tax_in_cents
  end

  def sub_total
    process_total :sub_total, :cost_in_cents
  end
  
  def amount( force_reload = false )
    (attribute_present? :amount_in_cents and !force_reload) ?
      Money.new(read_attribute(:amount_in_cents).to_i) :
      self.activities.inject(Money.new(0)){|sum,a| sum + ((a.cost) ? a.cost : Money.new(0)) + ((a.tax) ? a.tax : Money.new(0)) }
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
  
  def is_paid?( force_reload = false )
    (attribute_present? :is_paid  and !force_reload) ? 
      (read_attribute(:is_paid).to_i == 1) :
      amount_outstanding(true).zero?
  end
  
  def amount_paid( force_reload = false )
    Money.new( 
      (attribute_present? :amount_paid_in_cents and !force_reload) ? 
      read_attribute(:amount_paid_in_cents).to_i :
      InvoicePayment.sum( :amount_in_cents, :conditions => ['invoice_id = ?', id] ).to_i
    )
  end
  
  def amount_outstanding( force_reload = false )
    (attribute_present? :amount_outstanding_in_cents and !force_reload) ? 
      Money.new(read_attribute(:amount_outstanding_in_cents).to_i) :
      (amount(true) - amount_paid(true))
  end

  # This is a shortcut to the self.recommended_activities_for , and is provided as a shortcut when its necessary to update an existing invoice's
  # activities inclusion
  def recommended_activities
    Invoice.recommended_activities_for client_id, issued_on, self.activity_types, self.id
  end

  # Given a client_id, cut_at_or_before date, and (optionally) an array of types, we'll return the activities that should go into a corresponding invoice.
  # THis was placed here, b/c its conceivable that in the future, we may support an array for the client_id parameter...
  def self.recommended_activities_for(for_client_id, occurred_on_or_before, included_activity_types, for_invoice_id = nil)
    for_client_id = for_client_id.id if for_client_id.class == Client
    for_invoice_id = for_invoice_id.id if for_invoice_id.class == Invoice
    
    included_activity_types = included_activity_types.collect{|a| a.label.downcase}
    
    conditions = [
      'is_published = ? AND client_id = ? AND DATEDIFF(occurred_on, DATE(?)) <= 0',
      true,
      for_client_id,
      occurred_on_or_before
    ]
    
    # Slightly more complicated, for the type includes:
    if included_activity_types and included_activity_types.size > 0
      conditions[0] += ' AND ('+(['activity_type = ?'] * included_activity_types.size).join(' OR ')+')'
      conditions.push *included_activity_types
    else
      conditions[0] += ' AND activity_type IS NULL'
    end
    
    if for_invoice_id
      conditions[0] += ' AND ( invoice_id IS NULL OR invoice_id = ? )'
      conditions << for_invoice_id
    else
      conditions[0] += ' AND invoice_id IS NULL'
    end

    Activity.find :all, :conditions => conditions
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

  # When/if we save an invoice, and we determine that its changed or created as unpublished, we need to ensure that no payments are assigned to the invoice.
  # This means deleting any existing assignments should there be any.
  def clear_invoice_payments_if_unpublished   
    payment_assignments.clear if changes.has_key? "is_published" and !is_published
  end

  handle_extensions
end
