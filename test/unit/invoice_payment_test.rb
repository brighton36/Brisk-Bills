require File.dirname(__FILE__) + '/../test_helper'

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
    assert_equal false, invoices[0].is_paid?
    assert_equal false, invoices[1].is_paid?
    assert_equal false, invoices[2].is_paid?

    # Ensure that payments aren't marked as 'paid' until the invoice_payments have been applied.  Even though the balance is 0
    assert_equal false, payments[0].is_allocated?
    assert_equal false, payments[1].is_allocated?
    assert_equal false, payments[2].is_allocated?
    assert_equal false, payments[3].is_allocated?
    assert_equal false, payments[4].is_allocated?
    
    # Now start marking payments/invocies, and testing the corresponding is_ methods :
    InvoicePayment.quick_create! invoices[0], payments[2], 10.00

    assert_equal true, invoices[0].is_paid?
    assert_equal false, invoices[1].is_paid?
    assert_equal false, invoices[2].is_paid?
    assert_equal false, payments[0].is_allocated?
    assert_equal false, payments[1].is_allocated?
    assert_equal false, payments[2].is_allocated?
    assert_equal false, payments[3].is_allocated?
    assert_equal false, payments[4].is_allocated?

    InvoicePayment.quick_create! invoices[1], payments[2], 1.00
    InvoicePayment.quick_create! invoices[1], payments[3], 4.00    
    InvoicePayment.quick_create! invoices[1], payments[4], 10.00

    assert_equal true, invoices[0].is_paid?
    assert_equal true, invoices[1].is_paid?
    assert_equal false, invoices[2].is_paid?
    assert_equal false, payments[0].is_allocated?
    assert_equal false, payments[1].is_allocated?
    assert_equal true, payments[2].is_allocated?
    assert_equal true, payments[3].is_allocated?
    assert_equal true, payments[4].is_allocated?

    InvoicePayment.quick_create! invoices[2], payments[0], 2.00
    InvoicePayment.quick_create! invoices[2], payments[1], 3.00    
    
    # Everything should be allocated now - retest is_paid/allocated code
    assert_equal true, invoices[0].is_paid?
    assert_equal true, invoices[1].is_paid?
    assert_equal true, invoices[2].is_paid?

    assert_equal true, payments[0].is_allocated?
    assert_equal true, payments[1].is_allocated?
    assert_equal true, payments[2].is_allocated?
    assert_equal true, payments[3].is_allocated?
    assert_equal true, payments[4].is_allocated?
  end

  def test_invoice_dependent_delete
    client = Factory.create_client
    
    invoice = Factory.generate_invoice client, 99.00,  :issued_on => (DateTime.now << 1), :payment_assignments => [] 
    Factory.generate_payment client, 40.00,  :invoice_assignments => [InvoicePayment.new(:invoice => invoice, :amount => 40.00 )]
    Factory.generate_payment client, 40.00,  :invoice_assignments => [InvoicePayment.new(:invoice => invoice, :amount => 40.00 )]
    Factory.generate_payment client, 20.00,  :invoice_assignments => [InvoicePayment.new(:invoice => invoice, :amount => 19.00 )]
    
    assert_equal 3, InvoicePayment.find(:all).length

    invoice.destroy
    
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

  def test_bogus_allocations
    #  TODO: * People can't specifify more payment_allocations than the total payment's amount
    #  TODO: * People can't specifify more invoice_allocations than the total invoice's amount
    #     TODO: Make sure the updates do/don't trigger an error too ...
    #  TODO: * People can't specifify negative payment_allocations
  end

end
