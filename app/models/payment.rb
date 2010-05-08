class Payment < ActiveRecord::Base
  include ExtensibleObjectHelper
  include MoneyModelHelper
  
  belongs_to :client
  belongs_to :payment_method
  
  has_many :invoices, :through => :assigned_payments
  has_many :invoice_assignments, :class_name => 'InvoicePayment', :dependent => :delete_all
  
  validates_presence_of :client_id, :payment_method_id
  validates_numericality_of :amount, :allow_nil => false
  
  money :amount, :currency => false
  
  def initialize(*args)
    super(*args)
    self.paid_on = Time.now.beginning_of_day if paid_on.nil?
  end
  
  def amount_unallocated( force_reload = false )
    (attribute_present? :amount_unallocated_in_cents  and !force_reload) ? 
      Money.new(read_attribute(:amount_unallocated_in_cents).to_i) : 
      (amount - amount_allocated)
  end
  
  def amount_allocated( force_reload = false )
    Money.new(  
      (attribute_present? :amount_allocated_in_cents  and !force_reload) ? 
        read_attribute(:amount_allocated_in_cents).to_i : 
        ( InvoicePayment.sum(:amount_in_cents, :conditions => ['payment_id = ?', id]) || 0 )
    )
  end
  
  def is_allocated?( force_reload = false )
    (attribute_present? :is_allocated  and !force_reload) ? 
      (read_attribute(:is_allocated).to_i == 1) :
      amount_unallocated(true).zero?
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
