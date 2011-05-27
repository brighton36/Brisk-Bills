class Client < ActiveRecord::Base
  include IsActiveModelHelper
  
  has_and_belongs_to_many :client_representatives, :join_table => 'client_representatives_clients', :uniq => true
  
  has_many :client_eventlogs
  has_many :activities
  has_many :invoices
  has_many :payments
  
  has_many :employee_client_labor_rates, :class_name => 'EmployeeClientLaborRate', :dependent => :destroy
  
  has_many :client_financial_transactions
  
  before_destroy :ensure_not_referenced_on_destroy
  
  validates_presence_of :company_name

  def name
    self.company_name
  end
  
  def uninvoiced_activities_balance( force_reload = false )
    (attribute_present? :uninvoiced_activities_balance_in_cents and !force_reload) ?
      Money.new(read_attribute(:uninvoiced_activities_balance_in_cents).to_i) :
      (Activity.sum( Invoice::ACTIVITY_TOTAL_SQL, :conditions => ['client_id = ? AND is_published = ? AND invoice_id IS NULL',id, true] ) or 0)
  end
  
  # THis is the client's outstanding balance. This value is calculated based off the total invoices amount - total payments amount. And is 
  # Not determined based on invoice/payment assignments 
  def balance( force_reload = false )
    Money.new(
      (attribute_present? :balance_in_cents and !force_reload) ?
        read_attribute(:balance_in_cents).to_i :
        Client.find(
        :first, 
        :select => [
          'id',
          'company_name',
          '(
           IF(charges.charges_sum_in_cents IS NULL, 0,charges.charges_sum_in_cents) - 
           IF(deposits.payment_sum_in_cents IS NULL, 0, deposits.payment_sum_in_cents)
          ) AS sum_difference_in_cents'
        ].join(', '),
        :joins => [
          "LEFT JOIN(
            SELECT invoices.client_id, SUM(#{Invoice::ACTIVITY_TOTAL_SQL}) AS charges_sum_in_cents 
              FROM invoices 
              LEFT JOIN activities ON activities.invoice_id = invoices.id 
              GROUP BY invoices.client_id
          ) AS charges ON charges.client_id = clients.id",
          
          'LEFT JOIN (
            SELECT payments.client_id, SUM(payments.amount_in_cents) AS payment_sum_in_cents
              FROM payments 
              GROUP BY payments.client_id
          ) AS deposits ON deposits.client_id = clients.id '
        ].join(' '),
        :conditions => [ 'clients.id = ?', id]
        ).sum_difference_in_cents.to_i
    ) unless id.nil?
  end
  
  def ensure_not_referenced_on_destroy
    unless authorized_for?(:actions => :destroy)
      errors.add_to_base "Can't destroy a referenced employee"
      return false
    end
  end
  
  def authorized_for?(options)
    case options[:action]
      when :destroy
        [Invoice, Payment, Activity].each{ |k| return false if k.count(:all, :conditions => ['client_id = ?', id] ) > 0 }

        true
      else
        true
    end
  end
  
  def mailing_address
    ret = []
    
    %w( name address1 address2 ).each do |f|
      val = send(f.to_sym) and ( ret << val if val.length )
    end

    ret << '%s%s %s' % [
      (city.nil? or city.length == 0) ? '' : "#{city}, ", 
      state, 
      zip
    ]

    ret
  end
    
  # Returns an array of unsaved InvoicePayment objects, with unset payment_ids, and 'recommended' amounts.
  # If the provided amount exactly equals an outstanding invoice's amount, we return a InvoicePayment for the oldest such matching invoice. 
  # Otherwise, we start applying the amount to invoices in ascending order by issued_date.
  def recommend_invoice_assignments_for(amount)
    amount = amount.to_money

    invs = unpaid_invoices(
      :all,
      # Using this order forces the closest-amount match to be above anything else, followed by date sorting
      :order => '(amount_outstanding_in_cents = %d) DESC, issued_on ASC, created_at ASC' % amount.cents
    )

    unassigned_outstanding = invs.inject(Money.new(0)){|total, inv| total + inv.amount_outstanding}
    
    invs.collect{ |inv|
      if amount > 0 and unassigned_outstanding > 0
        assignment = (amount >= inv.amount_outstanding) ? 
            inv.amount_outstanding : 
            amount
        
        unassigned_outstanding -= assignment
        amount  -= assignment
        
        InvoicePayment.new :invoice => inv, :amount => assignment if assignment > 0
      end
    }.compact
  end
  
  # Returns an array of unsaved InvoicePayment objects, with unset invoice_ids, and 'recommended' amounts.
  # If the provided amount exactly equals an payment's unalloated amount, we return a InvoicePayment for the oldest such matching payment. 
  # Otherwise, we start applying the amount to payments in ascending order by issued_date.
  def recommend_payment_assignments_for(amount)
    amount = amount.to_money
    
    pymnts = unassigned_payments(
      :all,
      # Using this order forces the closest-amount match to be above anything else, followed by date sorting
      :order => '(amount_unallocated_in_cents = %d) DESC, paid_on ASC, created_at ASC' % amount.cents
    )

    current_client_balance = pymnts.inject(Money.new(0)){|total, pmnt| total - pmnt.amount_unallocated}
  
    pymnts.collect{ |unallocated_pmnt|
      if amount > 0 or current_client_balance < 0
        assignment = (unallocated_pmnt.amount_unallocated > amount) ?
          amount :
          unallocated_pmnt.amount_unallocated
        
        current_client_balance += assignment
        amount -= assignment
        
        InvoicePayment.new :payment => unallocated_pmnt, :amount => assignment if assignment > 0
      end
    }.compact
  end

  # Returns all the client's invoices for which the allocated payments is less than the invoice amount. Perhaps this should be a has_many,
  # But since we're using the find_with_totals that would get complicated... 
  def unpaid_invoices( how_many = :all, options = {} )
    Invoice.find_with_totals(
      how_many, 
      {:conditions => [
        [
        'client_id = ?',
        'is_published = ?',
        'IF(activities_total.total_in_cents IS NULL, 0,activities_total.total_in_cents) - '+
        'IF(invoices_total.total_in_cents IS NULL, 0,invoices_total.total_in_cents) > ?'
        ].join(' AND '),
        id, true, 0
      ]}.merge(options.reject{|k,v| k == :conditions})
    )
  end

  # Returns all the client's payments for which the invoice allocation is less than the payment amount. Perhaps this should be a has_many,
  # But since we're using the find_with_totals that would get complicated... 
  def unassigned_payments( how_many = :all, options = {} )
    Payment.find_with_totals( 
      how_many, 
      {:conditions => [
        [
        'client_id = ?',
        '(payments.amount_in_cents - IF(payments_total.amount_allocated_in_cents IS NULL, 0, payments_total.amount_allocated_in_cents) ) > ?'
        ].join(' AND '),
        id, 0
      ]}.merge(options.reject{|k,v| k == :conditions}) 
    )
  end

end