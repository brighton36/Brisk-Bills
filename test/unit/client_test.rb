require 'test_helper'
require 'test_unit_factory_helper'

class ClientTest < ActiveSupport::TestCase
  fixtures :clients
  fixtures :activity_types
  
  def test_is_active
    acme = Client.create! :company_name => 'ACME Inc.'

    base_clients = ["DeRose Design Consultants, Inc.", "Ashbritt Environmental, Inc.", "CC1 Companies, Inc.", "Academy Roofing", "Affordable Air", "B'nai Congregation", "CC1 Companies, Inc.", "Worldwide Super Abrasives", "Chase Entertainment", "Flying Chimp Media", "GSA", "Lighting Dynamics, Inc.", "Noble Residence", "Garcia Architect", "Scott Rovenger PA", "SarSam", "Gary Slopey", "Thompkins Residence", "United Steel Building"]

    assert_equal base_clients+["ACME Inc."], Client.find_active(:all).collect{|e| e.company_name}

    acme.is_active = false
    acme.save!

    assert_equal base_clients, Client.find_active(:all).collect{|e| e.company_name}

    assert_equal base_clients, Client.find_active(:all, :conditions => ['id > ?', 0]).collect{|e| e.company_name}

    assert_equal base_clients, Client.find_active(:all, :conditions => 'id > 0').collect{|e| e.company_name}

    assert_equal base_clients, Client.find_active(:all, :conditions => ['id > 0']).collect{|e| e.company_name}
  end

  def test_basic_unpaid_invoices
    client = Factory.create_client
    
    payments = []
    
    paid_invoices = []
    unpaid_invoices = []
    unpaid_invoices << Factory.generate_invoice( client, 100.00, :issued_on => (DateTime.now << 4), :is_published => true )
    paid_invoices   << Factory.generate_invoice( client, 202.00, :issued_on => (DateTime.now << 3), :is_published => true )
    unpaid_invoices << Factory.generate_invoice( client, 300.00, :issued_on => (DateTime.now << 2), :is_published => true )
    unpaid_invoices << Factory.generate_invoice( client, 400.00, :issued_on => (DateTime.now << 1), :is_published => true )
    
    # This is a basic test in an obvious and typical scenario. Note that we should be matching payments up when they equal invoices..
    payments << Factory.generate_payment( client, 202.00 )

    client_unpaid_invoices = client.unpaid_invoices
    
    assert_equal client_unpaid_invoices.length, unpaid_invoices.length
    client_unpaid_invoices.each{ |inv| assert unpaid_invoices.collect{|un_inv| un_inv.id}.include?(inv.id) }
    
    # Now we test a half payment, which shouldn't make a difference in what's marked as fully-paid:
    payments << Factory.generate_payment( client, 99.00 )

    client_unpaid_invoices = client.unpaid_invoices
    
    assert_equal client_unpaid_invoices.length, unpaid_invoices.length
    client_unpaid_invoices.each{ |inv| assert unpaid_invoices.collect{|un_inv| un_inv.id}.include?(inv.id) }
    
    # Delete all the invoices we just created:
    (paid_invoices+unpaid_invoices+payments).reject!{|o| o.delete }
    paid_invoices, unpaid_invoices, payments = [], [], []
    
    # Now try this for the case of a payment created before the invoices...
    payments << Factory.generate_payment(client, 23.00)

    paid_invoices   << Factory.generate_invoice( client, 8.00,  :issued_on => (DateTime.now << 4) )
    paid_invoices   << Factory.generate_invoice( client, 14.00, :issued_on => (DateTime.now << 4) )
    unpaid_invoices << Factory.generate_invoice( client, 30.00, :issued_on => (DateTime.now << 1) )
    unpaid_invoices << Factory.generate_invoice( client, 2.00,  :issued_on => (DateTime.now << 1) )

    client_unpaid_invoices = client.unpaid_invoices

    assert_equal client_unpaid_invoices.uniq.length, client_unpaid_invoices.length
    client_unpaid_invoices.each{ |inv| assert unpaid_invoices.collect{|un_inv| un_inv.id}.include?(inv.id) }
  end
  
  def test_basic_unassigned_payments
    client = Factory.create_client
    
    invoices = []
    
    unassigned_payments = []
    assigned_payments   = []
    unassigned_payments << Factory.generate_payment( client,  230.00 )
    unassigned_payments << Factory.generate_payment( client,  132.00 )
    assigned_payments   << Factory.generate_payment( client,  23.00 )
    unassigned_payments << Factory.generate_payment( client,  993.00 )
    
    # This is a basic test in an obvious and typical scenario. Note that we should be matching payments up when they equal invoices..
    invoices << Factory.generate_invoice( client, 23.00, :issued_on => (DateTime.now << 1) )

    client_unassigned_payments = client.unassigned_payments
    
    assert_equal unassigned_payments.length, client_unassigned_payments.length
    client_unassigned_payments.each{ |pymt| assert unassigned_payments.collect{|un_pymnt| un_pymnt.id}.include?(pymt.id) }

    # Now we test a partial invoice, which shouldn't make a difference in what's marked as unassigned:
    invoices << Factory.generate_invoice( client, 100.00 )

    client_unassigned_payments = client.unassigned_payments
    
    assert_equal unassigned_payments.length, client_unassigned_payments.length
    client_unassigned_payments.each{ |pymt| assert unassigned_payments.collect{|un_pymnt| un_pymnt.id}.include?(pymt.id) }

    # Delete all the payments we just created:
    (unassigned_payments+assigned_payments+invoices).reject!{|o| o.delete }
    assigned_payments, unassigned_payments, invoices = [], [], []
    
    # Now try this for the case of an invoice created before the payments...
    invoices << Factory.generate_invoice(client, 23.00, :issued_on => (DateTime.now << 1) )

    assigned_payments   << Factory.generate_payment( client, 8.00 )
    assigned_payments   << Factory.generate_payment( client, 14.00 )
    unassigned_payments << Factory.generate_payment( client, 30.00 )
    unassigned_payments << Factory.generate_payment( client, 2.00 )
    
    client_unassigned_payments = client.unassigned_payments
    
    assert_equal unassigned_payments.length, client_unassigned_payments.length
    client_unassigned_payments.each{ |pymt| assert unassigned_payments.collect{|un_pymnt| un_pymnt.id}.include?(pymt.id) }
  end

  def test_recommend_payment_assignments_for
    # Make sure the assignments make sense (equal value outstanding returned before any-outstanding)
    client = Factory.create_client
    
    payments = [
      Factory.generate_payment( client,  23.45,  :paid_on => (DateTime.now << 5) ),
      Factory.generate_payment( client,  202.02, :paid_on => (DateTime.now << 4) ),
      Factory.generate_payment( client,  2.40,   :paid_on => (DateTime.now << 3) ),
      Factory.generate_payment( client,  94.00,  :paid_on => (DateTime.now << 2) ),
      Factory.generate_payment( client,  2.40,   :paid_on => (DateTime.now << 1) )
    ]
    
    # First test that exact-matches are properly assigned:
    reccomended = client.recommend_payment_assignments_for(2.40)
    assert_equal 1, reccomended.length
    assert_equal payments[2].id, reccomended.first.payment_id
    
    reccomended = client.recommend_payment_assignments_for(94)
    assert_equal 1, reccomended.length
    assert_equal payments[3].id, reccomended.first.payment_id
    
    reccomended = client.recommend_payment_assignments_for(23.45)
    assert_equal 1, reccomended.length
    assert_equal payments[0].id, reccomended.first.payment_id

    # Now test partials:
    reccomended = client.recommend_payment_assignments_for(5.40)
    assert_equal 1, reccomended.length
    assert_equal payments[0].id, reccomended.first.payment_id
    
    reccomended = client.recommend_payment_assignments_for(225.47)
    assert_equal 2, reccomended.length
    assert_equal payments[0].id, reccomended[0].payment_id
    assert_equal payments[1].id, reccomended[1].payment_id

    reccomended = client.recommend_payment_assignments_for(229)
    assert_equal 4, reccomended.length
    assert_equal payments[0].id, reccomended[0].payment_id
    assert_equal payments[1].id, reccomended[1].payment_id
    assert_equal payments[2].id, reccomended[2].payment_id
    assert_equal payments[3].id, reccomended[3].payment_id

    reccomended = client.recommend_payment_assignments_for(25)
    assert_equal 2, reccomended.length
    assert_equal payments[0].id, reccomended[0].payment_id
    assert_equal payments[1].id, reccomended[1].payment_id

  end
  
  def test_recommend_invoice_assignments_for 
    # Make sure the assignments make sense (equal value outstanding returned before any-outstanding)  
    client = Factory.create_client
    
    invoices = [
      Factory.generate_invoice( client,  23.45,  :issued_on => (DateTime.now << 5) ),
      Factory.generate_invoice( client,  202.02, :issued_on => (DateTime.now << 4) ),
      Factory.generate_invoice( client,  2.40,   :issued_on => (DateTime.now << 3) ),
      Factory.generate_invoice( client,  94.00,  :issued_on => (DateTime.now << 2) ),
      Factory.generate_invoice( client,  2.40,   :issued_on => (DateTime.now << 1) )
    ]
    
    # First test that exact-matches are properly assigned:
    reccomended = client.recommend_invoice_assignments_for(2.40)
    assert_equal 1, reccomended.length
    assert_equal invoices[2].id, reccomended.first.invoice_id
    
    reccomended = client.recommend_invoice_assignments_for(94)
    assert_equal 1, reccomended.length
    assert_equal invoices[3].id, reccomended.first.invoice_id
    
    reccomended = client.recommend_invoice_assignments_for(23.45)
    assert_equal 1, reccomended.length
    assert_equal invoices[0].id, reccomended.first.invoice_id

    # Now test partials:
    reccomended = client.recommend_invoice_assignments_for(5.40)
    assert_equal 1, reccomended.length
    assert_equal invoices[0].id, reccomended.first.invoice_id
    
    reccomended = client.recommend_invoice_assignments_for(225.47)
    assert_equal 2, reccomended.length
    assert_equal invoices[0].id, reccomended[0].invoice_id
    assert_equal invoices[1].id, reccomended[1].invoice_id

    reccomended = client.recommend_invoice_assignments_for(229)
    assert_equal 4, reccomended.length
    assert_equal invoices[0].id, reccomended[0].invoice_id
    assert_equal invoices[1].id, reccomended[1].invoice_id
    assert_equal invoices[2].id, reccomended[2].invoice_id
    assert_equal invoices[3].id, reccomended[3].invoice_id

    reccomended = client.recommend_invoice_assignments_for(25)
    assert_equal 2, reccomended.length
    assert_equal invoices[0].id, reccomended[0].invoice_id
    assert_equal invoices[1].id, reccomended[1].invoice_id
  end
  
  def test_negative_recommend_invoice_payment_assignments_for
    # Make sure the assignments make sense (equal value outstanding returned before any-outstanding)  
    client = Factory.create_client
    
    invoices = [
      Factory.generate_invoice( client,  20.00, :issued_on => (DateTime.now << 5) ),
      Factory.generate_invoice( client,  -40.0, :issued_on => (DateTime.now << 4) ),
      Factory.generate_invoice( client,  8.00,  :is_published => true, :issued_on => (DateTime.now << 3) ),
      Factory.generate_invoice( client,  -2.00, :issued_on => (DateTime.now << 2) ),
      Factory.generate_invoice( client,  16.00, :issued_on => (DateTime.now << 1) )
    ]
    
    # First test that exact-matches are properly assigned:
    reccomended = client.recommend_invoice_assignments_for(20.00)
    assert_equal 1, reccomended.length
    assert_equal invoices[0].id, reccomended.first.invoice_id
    
    reccomended = client.recommend_invoice_assignments_for(8.00)
    assert_equal 1, reccomended.length
    assert_equal invoices[2].id, reccomended.first.invoice_id
    
    reccomended = client.recommend_invoice_assignments_for(16.00)
    assert_equal 1, reccomended.length
    assert_equal invoices[4].id, reccomended.first.invoice_id

    reccomended = client.recommend_invoice_assignments_for(16.00)
    assert_equal 1, reccomended.length
    assert_equal invoices[4].id, reccomended.first.invoice_id

    # And check what happens if we have a negative amount?
    reccomended = client.recommend_invoice_assignments_for(-40.00)
    assert_equal 0, reccomended.length

    # Now test partials:
    reccomended = client.recommend_invoice_assignments_for(5.00)
    assert_equal 1, reccomended.length
    assert_equal invoices[0].id, reccomended.first.invoice_id
    
    reccomended = client.recommend_invoice_assignments_for(25.00)
    assert_equal 2, reccomended.length
    assert_equal invoices[0].id, reccomended[0].invoice_id
    assert_equal invoices[2].id, reccomended[1].invoice_id

    reccomended = client.recommend_invoice_assignments_for(48)
    assert_equal 3, reccomended.length
    assert_equal invoices[0].id, reccomended[0].invoice_id
    assert_equal invoices[2].id, reccomended[1].invoice_id
    assert_equal invoices[4].id, reccomended[2].invoice_id

    reccomended = client.recommend_invoice_assignments_for(28)
    assert_equal 2, reccomended.length
    assert_equal invoices[0].id, reccomended[0].invoice_id
    assert_equal invoices[2].id, reccomended[1].invoice_id
  end

  # Now that we support multiple unpublished invoices - let's make sure that our payment recomendations aren't improperly
  # assigning payments to unpublished invoices
  def test_unpublished_invoice_payment_assignments
    client = Factory.create_client
    
    # First create three published invoices:
    invoices = [
      Factory.generate_invoice( client,  400.0,  :issued_on => (DateTime.now << 5) ),
      Factory.generate_invoice( client,  50.00,  :issued_on => (DateTime.now << 4) ),
      Factory.generate_invoice( client,  800.00, :issued_on => (DateTime.now << 3) )
    ]
    payments = []
      
    assert_equal 1250.00, client.balance

    # Unpublish invoices 1 & 2
    [invoices[0], invoices[1]].each do |inv|
      inv.is_published = false
      inv.save!
    end

    # Create a payment for the first
    payments << Factory.generate_payment( client, 800.00 )

    # Publish invoice 2:
    invoices[1].is_published = true
    invoices[1].save!
    
    # Create payments for the third
    payments << Factory.generate_payment( client, 26.00 )
    payments << Factory.generate_payment( client, 24.00 )

    # Set the 1st published
    invoices[0].is_published = true
    invoices[0].save!
    
    # Create a payment for the second
    payments << Factory.generate_payment( client, 500.00 )
    
    # Now we test all the invoice_payment mappings to be sure they make sense ..
    assert_equal true, invoices[0].is_paid?(true)
    assert_equal [payments[3].id], invoices[0].payment_assignments(true).collect(&:payment_id)

    assert_equal true, invoices[1].is_paid?(true)
    assert_equal [payments[1].id, payments[2].id], invoices[1].payment_assignments(true).collect(&:payment_id)
    
    assert_equal true, invoices[2].is_paid?(true)
    assert_equal [payments[0].id], invoices[2].payment_assignments(true).collect(&:payment_id)
  end

  def test_find_invoiceable_clients_at

    # Because we're using fixtures - we have some pre-existing clients and activities here . 
    # I really don't want 'em for this test though:
    Client.find(:all).each{|c| c.destroy}
    Activity.find(:all).each{|a| a.destroy}

    # OK - time to get started:
    
    Factory.generate_payment Factory.create_client(:company_name => "All Paid Up, Inc."), Money.new(10000)

    
    clientA = Factory.create_client :company_name => "Client A"
    clientB = Factory.create_client :company_name => "Client B"
    clientC = Factory.create_client :company_name => "Client C"
    clientD = Factory.create_client :company_name => "Client D"

    Factory.create_labor( {}, {:client => clientA, :occurred_on => (DateTime.now << 1)} )
    Factory.create_labor( {}, {:client => clientA, :occurred_on => (DateTime.now << 2)} )
    Factory.create_labor( {}, {:client => clientA, :occurred_on => (DateTime.now >> 1)} )
    Factory.create_labor( {}, {:client => clientB, :occurred_on => (DateTime.now << 1)} )
    Factory.create_labor( {}, {:client => clientC, :occurred_on => (DateTime.now >> 1)} )
    Factory.create_labor( {}, {:client => clientD, :occurred_on => (DateTime.now << 1), :is_published => false} )
    Factory.create_labor( {}, {:client_id => nil, :occurred_on => (DateTime.now << 1)} )

    invoiceable_clients = Client.find_invoiceable_clients_at(DateTime.now)

    assert_equal 2, invoiceable_clients.length
    assert_equal [clientA.id, clientB.id], invoiceable_clients.collect(&:id)
  end
end
