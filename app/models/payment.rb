class Payment < ActiveRecord::Base
  include ExtensibleObjectHelper
  include MoneyModelHelper
  
  after_create  :create_invoice_payments
  after_destroy :destroy_invoice_payments
  # NOTE: after_update is not needed , because payment's can't be updated...
  
  belongs_to :client
  belongs_to :payment_method
  
  has_many :invoices, :through => 'invoice_payments'
  
  validates_presence_of :client_id, :payment_method_id
  validates_numericality_of :amount, :allow_nil => false
  
  money :amount, :currency => false
  
  def initialize(*args)
    super(*args)
    self.paid_on = Time.now.beginning_of_day if paid_on.nil?
  end
  
  def create_invoice_payments    
    # NOTE: Orders by oldest outstanding date first:
    unpaid_invoices = Invoice.find_with_totals(
      :all, 
      :conditions => [
        [
        'client_id = ?',
        'IF(activities_total.total_in_cents IS NULL, 0,activities_total.total_in_cents) - '+
        'IF(invoices_total.total_in_cents IS NULL, 0,invoices_total.total_in_cents) > ?'
         ].join(' AND '),
        client_id, 
        0
      ]
    )

    current_client_balance = Money.new(0)
    unpaid_invoices.each { |inv| current_client_balance += inv.amount_outstanding }
    
    currently_unallocated = amount_unallocated

    unpaid_invoices.each do |unpaid_invoice|
      break if currently_unallocated <= 0 or current_client_balance <= 0

      payment_allocation = (currently_unallocated >= unpaid_invoice.amount_outstanding) ? 
        unpaid_invoice.amount_outstanding : 
        currently_unallocated
      
      InvoicePayment.create! :payment => self, :invoice => unpaid_invoice, :amount => payment_allocation

      current_client_balance -= payment_allocation
      currently_unallocated  -= payment_allocation
    end
  end
  
  def destroy_invoice_payments
    InvoicePayment.destroy_all ['payment_id = ?', id]
  end
  
  def amount_unallocated
    (attribute_present? :amount_unallocated_in_cents) ? 
      Money.new(read_attribute(:amount_unallocated_in_cents).to_i) : 
      (amount - amount_allocated)
  end
  
  def amount_allocated
    Money.new( 
      ( 
        (attribute_present? :amount_allocated_in_cents) ? 
          read_attribute(:amount_allocated_in_cents) : 
          InvoicePayment.sum(:amount_in_cents, :conditions => ['payment_id = ?', id])
      ) || 0
    )
  end
  
  def validate_on_update
    errors.add_to_base "Payments can't be updated after creation"
  end
  
  def name  
    '%.2f Payment from %s'  % [ amount, client.company_name ]
  end

  def self.find_with_totals( how_many = :all, options = {} )
    cast_amount_allocated = 'IF(payments_total.amount_allocated_in_cents IS NULL, 0, payments_total.amount_allocated_in_cents)'
    
    joins = 'LEFT JOIN ('+
      'SELECT payment_id, SUM(amount_in_cents) AS amount_allocated_in_cents FROM invoice_payments GROUP BY payment_id'+
    ') AS payments_total ON payments_total.payment_id = payments.id'
    
    Payment.find( 
      how_many,
      {
        :select => [
          'payments.id',
          'payments.amount_in_cents',
          "#{cast_amount_allocated} AS amount_allocated_in_cents",
          "payments.amount_in_cents - #{cast_amount_allocated} AS amount_unallocated_in_cents"
        ].join(', '),
        :order => 'paid_on ASC',
        :joins => joins,
        :group => 'payments.id'
      }.merge(options)
    )
  end
  
  handle_extensions
end
