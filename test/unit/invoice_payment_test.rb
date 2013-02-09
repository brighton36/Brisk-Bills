require 'test_helper'
require 'test_unit_factory_helper'

class InvoicePaymentTest < ActiveSupport::TestCase

  def test_invoice_payment_marking
    client = Factory.create_client
    
    invoices = [
      Factory.generate_invoice( client, 10.00,  :issued_on => (DateTime.now << 4), :payment_assignments => [] ),
      Factory.generate_invoice( client, 15.00,  :issued_on => (DateTime.now << 3), :payment_assignments => [] ),
      Factory.generate_invoice( client, 5.00,   :issued_on => (DateTime.now << 2), :payment_assignments => [] ),
    ]

    assert_equal 30.00, client.balance
    
    payments = [
      Factory.generate_payment( client, 2.00,  :invoice_assignments => [] ),
      Factory.generate_payment( client, 3.00,  :invoice_assignments => [] ),
      Factory.generate_payment( client, 11.00, :invoice_assignments => [] ),
      Factory.generate_payment( client, 4.00,  :invoice_assignments => [] ),
      Factory.generate_payment( client, 10.00, :invoice_assignments => [] )
    ]

    assert_equal 0.00, client.balance
    
    # Ensure that invoices aren't marked as 'paid' until the invoice_payments have been applied.  Even though the balance is 0
    assert_equal false, invoices[0].is_paid?(true)
    assert_equal false, invoices[1].is_paid?(true)
    assert_equal false, invoices[2].is_paid?(true)

    # Ensure that payments aren't marked as 'paid' until the invoice_payments have been applied.  Even though the balance is 0
    assert_equal false, payments[0].is_allocated?(true)
    assert_equal false, payments[1].is_allocated?(true)
    assert_equal false, payments[2].is_allocated?(true)
    assert_equal false, payments[3].is_allocated?(true)
    assert_equal false, payments[4].is_allocated?(true)
    
    # Now start marking payments/invocies, and testing the corresponding is_ methods :
    InvoicePayment.quick_create! invoices[0], payments[2], 10.00

    assert_equal true, invoices[0].is_paid?(true)
    assert_equal false, invoices[1].is_paid?(true)
    assert_equal false, invoices[2].is_paid?(true)
    assert_equal false, payments[0].is_allocated?(true)
    assert_equal false, payments[1].is_allocated?(true)
    assert_equal false, payments[2].is_allocated?(true)
    assert_equal false, payments[3].is_allocated?(true)
    assert_equal false, payments[4].is_allocated?(true)

    InvoicePayment.quick_create! invoices[1], payments[2], 1.00
    InvoicePayment.quick_create! invoices[1], payments[3], 4.00    
    InvoicePayment.quick_create! invoices[1], payments[4], 10.00

    assert_equal true, invoices[0].is_paid?(true)
    assert_equal true, invoices[1].is_paid?(true)
    assert_equal false, invoices[2].is_paid?(true)
    assert_equal false, payments[0].is_allocated?(true)
    assert_equal false, payments[1].is_allocated?(true)
    assert_equal true, payments[2].is_allocated?(true)
    assert_equal true, payments[3].is_allocated?(true)
    assert_equal true, payments[4].is_allocated?(true)

    InvoicePayment.quick_create! invoices[2], payments[0], 2.00
    InvoicePayment.quick_create! invoices[2], payments[1], 3.00    
    
    # Everything should be allocated now - retest is_paid/allocated code
    assert_equal true, invoices[0].is_paid?(true)
    assert_equal true, invoices[1].is_paid?(true)
    assert_equal true, invoices[2].is_paid?(true)

    assert_equal true, payments[0].is_allocated?(true)
    assert_equal true, payments[1].is_allocated?(true)
    assert_equal true, payments[2].is_allocated?(true)
    assert_equal true, payments[3].is_allocated?(true)
    assert_equal true, payments[4].is_allocated?(true)
  end

  # How well does find_recomended_invoices work for a negative invoice with a credit/negative amount -payment? Write a test:
  def test_negative_invoice_payment_marking
    client = Factory.create_client
    
    invoices = [
      Factory.generate_invoice( client, 10.00,  :issued_on => (DateTime.now << 4), :payment_assignments => [] ),
      Factory.generate_invoice( client, -15.00, :issued_on => (DateTime.now << 3), :payment_assignments => [] ),
      Factory.generate_invoice( client, -5.00,  :issued_on => (DateTime.now << 2), :payment_assignments => [] ),
    ]

    assert_equal -10.00, client.balance

    # Negative invoices are always marked paid
    assert_equal false, invoices[0].is_paid?(true)
    assert_equal true,  invoices[1].is_paid?(true)
    assert_equal true,  invoices[2].is_paid?(true)
    
    payments = [
      Factory.generate_payment( client, 5.00,   :invoice_assignments => 
        [InvoicePayment.new(:invoice => invoices[0], :amount => 5.00 )]
      ),
      Factory.generate_payment( client, 5.00,   :invoice_assignments => 
        [InvoicePayment.new(:invoice => invoices[0], :amount => 5.00 )]
      )
    ]

    assert_equal -20.00, client.balance

    # Everything should be paid now:
    assert_equal true, invoices[0].is_paid?(true)
    assert_equal true, invoices[1].is_paid?(true)
    assert_equal true, invoices[2].is_paid?(true)
    
    # Now what if the invoice they have an invoice for -$20, and an invoice for +$12. Their outstanding balance is -$8,
    # but if they try to make a payment for $5, will we freak on them?
    
    # Just for goo measure let's generate a new invoice:
    invoices << Factory.generate_invoice( client, 12.00,  :issued_on => (DateTime.now << 1), :payment_assignments => [] )

    assert_equal -8.00, client.balance
    
    assert_equal true, invoices[0].is_paid?(true)
    assert_equal true, invoices[1].is_paid?(true)
    assert_equal true, invoices[2].is_paid?(true)
    assert_equal false, invoices[3].is_paid?(true)
    
    payments << Factory.generate_payment( client, 12.00,   :invoice_assignments => 
        [InvoicePayment.new(:invoice => invoices[3], :amount => 12.00 )]
    )
    
    # and make sure we're cool:
    assert_equal true, invoices[0].is_paid?(true)
    assert_equal true, invoices[1].is_paid?(true)
    assert_equal true, invoices[2].is_paid?(true)
    assert_equal true, invoices[3].is_paid?(true)
    
    assert_equal -20.00, client.balance
  end

  def test_invoice_dependent_delete
    client = Factory.create_client
    
    invoice = Factory.generate_invoice client, 99.00,  :issued_on => (DateTime.now << 1), :payment_assignments => []
    Factory.generate_payment client, 40.00,  :invoice_assignments => [InvoicePayment.new(:invoice => invoice, :amount => 40.00 )]
    Factory.generate_payment client, 40.00,  :invoice_assignments => [InvoicePayment.new(:invoice => invoice, :amount => 40.00 )]
    Factory.generate_payment client, 20.00,  :invoice_assignments => [InvoicePayment.new(:invoice => invoice, :amount => 19.00 )]
    
    assert_equal 3, InvoicePayment.find(:all).length

    invoice.is_published = false
    assert_not_equal false, invoice.destroy # False would indicate that the invoice didnt delete successfully
    
    # Now make sure all our InvoicePayments were also destroyed:
    assert_equal 0, InvoicePayment.find(:all).length
  end
  
  def test_invoice_payments_dependent_delete
    client = Factory.create_client
    
    payment = Factory.generate_payment client, 13.00,  :invoice_assignments => []
    
    Factory.generate_invoice client, 4.00,  :issued_on => (DateTime.now << 1), :payment_assignments => [
      InvoicePayment.new(:payment => payment, :amount => 4.00 )
    ]
    Factory.generate_invoice client, 4.00,  :issued_on => (DateTime.now << 1), :payment_assignments => [
      InvoicePayment.new(:payment => payment, :amount => 4.00 )
    ]
    Factory.generate_invoice client, 3.00,  :issued_on => (DateTime.now << 1), :payment_assignments => [
      InvoicePayment.new(:payment => payment, :amount => 3.00 )
    ]
    
    assert_equal 3, InvoicePayment.find(:all).length

    payment.destroy
    
    # Now make sure all our InvoicePayments were also destroyed:
    assert_equal 0, InvoicePayment.find(:all).length
  end

  def test_bogus_invoice_payment_amounts
    client = Factory.create_client
    
    ip = nil
    
    invoice = Factory.generate_invoice client,  100.00,  :issued_on => (DateTime.now << 1),  :payment_assignments => []
    paymentA = Factory.generate_payment client,  20.00, :invoice_assignments => []
    paymentB = Factory.generate_payment client, 110.00, :invoice_assignments => []
    
    #  Test: People can't specifify more allocations than the total payment's amount
    ip = InvoicePayment.new :payment => paymentA, :invoice => invoice, :amount => 21.00
    assert_equal false, ip.valid?
    assert_equal "exceeds the payment's remainder amount", ip.errors.on('amount')

    #  Test: People can't specifify more allocations than the total invoice's amount
    ip = InvoicePayment.create :payment => paymentB, :invoice => invoice, :amount => 101.00
    assert_equal false, ip.valid?
    assert_equal "exceeds the invoice's remainder balance", ip.errors.on('amount')
        
    #  Test: Trying the case of a second/multiple payments which exceed the invoice balance..
    invoice = Factory.generate_invoice client,  20.00,  :issued_on => (DateTime.now << 1), :payment_assignments => []
    paymentA = Factory.generate_payment client,  12.00, :invoice_assignments => [
      InvoicePayment.new( :invoice => invoice, :amount => 12.00)
    ]
    paymentB = Factory.generate_payment client,  12.00, :invoice_assignments => []

    ip = InvoicePayment.create :payment => paymentB, :invoice => invoice, :amount => 12.00
    assert_equal false, ip.valid?
    assert_equal "exceeds the invoice's remainder balance", ip.errors.on('amount')

    # Now try the case of multiple invoices which exceed the payment balance..
    invoiceA = Factory.generate_invoice client,  40.00,  :issued_on => (DateTime.now << 1), :payment_assignments => []
    invoiceB = Factory.generate_invoice client,  35.00,  :issued_on => (DateTime.now << 1), :payment_assignments => []
    
    payment = Factory.generate_payment client,  70.00, :invoice_assignments => [
      InvoicePayment.new( :invoice => invoiceA, :amount => 40.00)
    ]

    ip = InvoicePayment.create :payment => payment, :invoice => invoiceB, :amount => 35.00
    assert_equal false, ip.valid?
    assert_equal "exceeds the payment's remainder amount", ip.errors.on('amount')
  end

  def test_bogus_invoice_allocations
    client = Factory.create_client
    
    # This is a repeat of some of the above tests, but we're ensuring that we fail during the invoice model's creation
    paymentA = Factory.generate_payment client,  4.00, :invoice_assignments => []
    paymentB = Factory.generate_payment client,  8.00, :invoice_assignments => []
    paymentC = Factory.generate_payment client,  8.00, :invoice_assignments => []
    
    assert_raise ActiveRecord::RecordInvalid do
      Factory.generate_invoice client,  16.00,  :issued_on => (DateTime.now << 1), :payment_assignments => [
        InvoicePayment.new( :payment => paymentA, :amount => 4.00 ),
        InvoicePayment.new( :payment => paymentB, :amount => 8.00 ),
        InvoicePayment.new( :payment => paymentC, :amount => 5.00 ) # <-- this one's invalid, b/c its greater than the invoice price
      ]
    end
    
    assert_raise ActiveRecord::RecordInvalid do
      Factory.generate_invoice client,  16.00,  :issued_on => (DateTime.now << 1), :payment_assignments => [
        InvoicePayment.new( :payment => paymentA, :amount => 8.00 ), # <-- this one's invalid, b/c its greater than the payment total
        InvoicePayment.new( :payment => paymentB, :amount => 4.00 ),
        InvoicePayment.new( :payment => paymentC, :amount => 4.00 )
      ]
    end
  end

  def test_bogus_payment_allocations
    client = Factory.create_client
    
    # This is a repeat of some of the above tests, but we're ensuring that we fail during the payment model's creation
    invoiceA = Factory.generate_invoice client,  3.00,  :issued_on => (DateTime.now << 1), :payment_assignments => []
    invoiceB = Factory.generate_invoice client,  6.00,  :issued_on => (DateTime.now << 1), :payment_assignments => []
    invoiceC = Factory.generate_invoice client,  6.00,  :issued_on => (DateTime.now << 1), :payment_assignments => []
    
    assert_raise ActiveRecord::RecordInvalid do
      Factory.generate_payment client,  12.00, :invoice_assignments => [
        InvoicePayment.new( :invoice => invoiceA, :amount => 3.00 ),
        InvoicePayment.new( :invoice => invoiceB, :amount => 6.00 ),
        InvoicePayment.new( :invoice => invoiceC, :amount => 4.00 ) # <-- this one's invalid, b/c its greater than the payment price
      ]
    end

    assert_raise ActiveRecord::RecordInvalid do
      Factory.generate_payment client,  12.00, :invoice_assignments => [
        InvoicePayment.new( :invoice => invoiceA, :amount => 6.00 ),# <-- this one's invalid, b/c its greater than the invoice total
        InvoicePayment.new( :invoice => invoiceB, :amount => 3.00 ),
        InvoicePayment.new( :invoice => invoiceC, :amount => 3.00 ) 
      ]
    end
  end

  def test_invoice_payment_amount_not_negative
    client = Factory.create_client
    
    # People can't specifify negative payment_allocations
    invoice = Factory.generate_invoice client,  5.00,  :issued_on => (DateTime.now << 1), :payment_assignments => []
    payment = Factory.generate_payment client,  5.00, :invoice_assignments => []
    
    ip = InvoicePayment.create :payment => payment, :invoice => invoice, :amount => -5.00
    
    assert_equal false, ip.valid?
    assert_equal "must be greater than or equal to 0", ip.errors.on('amount')
  end
  
  def test_payments_unapplyable_to_unpublished_invoices
    client = Factory.create_client
    
    invoice = nil
    payment = nil
    
    # Ensure Invoice :payment_assignments create fails with unpublished unvoice
    payment = Factory.generate_payment( client,  40.00 , :invoice_assignments => [] )
    
    assert_raise(ActiveRecord::RecordInvalid) do
      invoice = Factory.generate_invoice( client, 40.00, :is_published => false, :payment_assignments => [
        InvoicePayment.new( :payment => payment, :amount => 40.00 ) 
      ] )
    end

    # Ensure Payment :invoice_assignments create fails with unpublished unvoice
    invoice = Factory.generate_invoice( client, 50.00, :is_published => false, :payment_assignments => [])

    assert_raise(ActiveRecord::RecordInvalid) do
      payment = Factory.generate_payment( client,  50.00 , :invoice_assignments => [
        InvoicePayment.new( :invoice => invoice, :amount => 50.00 ) 
      ] )
    end
    
    # Test that negative assignments aren't accepted:
    invoice = Factory.generate_invoice( client, 10.00, :is_published => false, :payment_assignments => [])

    assert_raise(ActiveRecord::RecordInvalid) do
      payment = Factory.generate_payment( client,  5.00 , :invoice_assignments => [
        InvoicePayment.new( :invoice => invoice, :amount => -1.00 ) 
      ] )
    end

    # Test InvoicePayment create fails with unpublished unvoice
    invoice = Factory.generate_invoice( client, 60.00, :is_published => false, :payment_assignments => [])
    payment = Factory.generate_payment( client, 60.00, :invoice_assignments => [] )
    
    ip = InvoicePayment.new :invoice => invoice, :payment => payment, :amount => 60.00
    
    assert_raise(ActiveRecord::RecordInvalid) { ip.save! }
    assert ip.errors.invalid?(:invoice)
  end
  
  # Mostly I did this to test out view-caching isn't screwing anything up here when we manually attach (and don't save InvoicePayment(s)
  def test_payment_amount_unallocated
    client = Factory.create_client
    
    invoice = Factory.generate_invoice( client, 50.00, :is_published => false, :payment_assignments => [])
    payment = Factory.generate_payment( client, 60.00, :invoice_assignments => [] )
    
    assert_equal Money.new(0), payment.amount_allocated
    assert_equal Money.new(6000), payment.amount_unallocated
    
    payment.invoice_assignments << InvoicePayment.new( :invoice => invoice, :amount => 50.00 )
    
    assert_equal Money.new(5000), payment.amount_allocated
    assert_equal Money.new(1000), payment.amount_unallocated
  end
  
  # Mostly I did this to test out view-caching isn't screwing anything up here when we manually attach (and don't save InvoicePayment(s)
  def test_invoice_amount_outstanding
    client = Factory.create_client
    
    invoice = Factory.generate_invoice( client, 60.00, :is_published => false, :payment_assignments => [])
    payment = Factory.generate_payment( client, 50.00, :invoice_assignments => [] )
    
    assert_equal Money.new(0), invoice.amount_paid
    assert_equal Money.new(6000), invoice.amount_outstanding
    
    invoice.payment_assignments << InvoicePayment.new( :payment => payment, :amount => 50.00 )
    
    assert_equal Money.new(1000), invoice.amount_outstanding
    assert_equal Money.new(5000), invoice.amount_paid
  end
end
