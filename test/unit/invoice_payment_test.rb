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
    
    # TODO: Start marking payments/invocies using :invoice_assignments.create!

    # (TODO: Then retest - the is_XXXX? 

    # TODO: * Also - in the case that an invoice price is adjusted after it was marked paid (becomes higher or lower) we don't need to have controller or payment logic to deal with this

    # TODO: * We need to make sure clear_invoice_payments_if_unpublished works on create and update...
  end


  def test_invoice_payments_dependent_delete
    #  TODO: * ensure that the has_many :invoice_assignments, :class_name => 'InvoicePayment', :dependent => :delete_all 
    #        * works the way we 'd think
    #        * And works similarly on Payment
  end

  def test_bogus_allocations
    #  TODO: * People can't specifify more payment_allocations than the total payment's amount
    #  TODO: * People can't specifify negative payment_allocations
  end

end
