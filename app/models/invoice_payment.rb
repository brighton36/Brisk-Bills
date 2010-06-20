class InvoicePayment < ActiveRecord::Base
  include MoneyModelHelper
  
  belongs_to :payment
  belongs_to :invoice
  
  money :amount, :currency => false
  
  validates_numericality_of :amount, :greater_than_or_equal_to => 0
  validate :amount_not_greater_than_payment_or_invoice_totals
  validate :validate_invoice_is_published

  # Ensure the assigned invoice is_published, otherwise, we shouldn't be able to mark it paid
  def validate_invoice_is_published
    errors.add :invoice, "can't be assigned to an unpublished invoice" if invoice and !invoice.is_published
  end

  # This is just to make the code a little easier to type/read. Its a create!, just without all the option verbosity.
  # Note: We accept either and invoice object or invoice_id, and either a payment object or payment_id
  def self.quick_create!(invoice_id, payment_id, amount)    
    InvoicePayment.create!(
      :invoice_id => (invoice_id.class == Invoice) ? invoice_id.id : invoice_id, 
      :payment_id => (payment_id.class == Payment) ? payment_id.id : payment_id, 
      :amount     => amount.to_money
    )
  end

  # Here, we verify that newly created and/or updated InvoicePayments, won't have an amount which adds up to a greater value 
  # than would be possible for the associated invoice or payment
  def amount_not_greater_than_payment_or_invoice_totals
    conditions_fields = []
    conditions_values = []    

    # If we're updating an existing payment, it gets a little more complicated:
    if id
      conditions_fields << 'id != ?'
      conditions_values << id
    end
    
    errors.add :amount, "exceeds the payment's remainder amount" if payment_id and payment.amount < (
      Money.new(
        InvoicePayment.sum(
          :amount_in_cents, 
          :conditions => [(conditions_fields+['payment_id = ?']).join(' AND ')]+conditions_values+[payment_id] 
        ).to_i
      ) + amount)

    # This could act flaky on you if you didn't specify activities for your invoice at creation time (and did specify invoice_payments)
    # this , b/c we're checking the invoice amount below and unlike payments, invoices have no amount field
     errors.add :amount, "exceeds the invoice's remainder balance" if invoice_id and invoice.amount < (
      Money.new(
        InvoicePayment.sum(
          :amount_in_cents, 
          :conditions => [(conditions_fields+['invoice_id = ?']).join(' AND ')]+conditions_values+[invoice_id] 
        ).to_i
      ) + amount)
  end
end
