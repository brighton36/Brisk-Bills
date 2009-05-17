class Payment < ActiveRecord::Base
  include ExtensibleObjectHelper
  
  after_create  :create_invoice_payments
  after_destroy :destroy_invoice_payments
  # NOTE: after_update is not needed , because payment's can't be updated...
  
  belongs_to :client
  belongs_to :payment_method
  
  has_many :invoices, :through => 'invoice_payments'
  
  validates_presence_of :client_id, :payment_method_id
  validates_numericality_of :amount, :allow_nil => false
  
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
        'IF(activities_total.total IS NULL, 0,activities_total.total) - '+
        'IF(invoices_total.total IS NULL, 0,invoices_total.total) > ?'
         ].join(' AND '),
        client_id, 
        0
      ]
    )

    current_client_balance = BigDecimal.new('0.0')
    unpaid_invoices.each { |inv| current_client_balance += BigDecimal.new(inv.amount_outstanding.to_s) }
    
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
    ret = (attribute_present? :amount_unallocated) ? read_attribute(:amount_unallocated) : (amount - amount_allocated)
    
    BigDecimal.new ret.to_s
  end
  
  def amount_allocated
    ret = (attribute_present? :amount_allocated) ? 
      read_attribute(:amount_allocated) : 
      InvoicePayment.sum(:amount, :conditions => ['payment_id = ?', id])
    
    ret ||= 0
    
    BigDecimal.new ret.to_s
  end
  
  def validate_on_update
    errors.add_to_base "Payments can't be updated after creation"
  end
  
  def name  
    '%.2f Payment from %s'  % [ amount, client.company_name ]
  end

  def self.find_with_totals( how_many = :all, options = {} )
    cast_amount_allocated = 'IF(payments_total.amount_allocated IS NULL, 0, payments_total.amount_allocated)'
    
    joins = 'LEFT JOIN ('+
      'SELECT payment_id, SUM(amount) AS amount_allocated FROM invoice_payments GROUP BY payment_id'+
    ') AS payments_total ON payments_total.payment_id = payments.id'
    
    Payment.find( 
      how_many,
      {
        :select => [
          'payments.id',
          'payments.amount',
          "#{cast_amount_allocated} AS amount_allocated",
          "payments.amount - #{cast_amount_allocated} AS amount_unallocated"
        ].join(', '),
        :order => 'paid_on ASC',
        :joins => joins,
        :group => 'payments.id'
      }.merge(options)
    )
  end
  
  handle_extensions
end
