require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_unit_factory_helper.rb'

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
    
    paid_invoices = []
    unpaid_invoices = []
    unpaid_invoices << Factory.generate_invoice( client, 100.00, :issued_on => (DateTime.now << 4), :is_published => true )
    paid_invoices   << Factory.generate_invoice( client, 202.00, :issued_on => (DateTime.now << 3), :is_published => true )
    unpaid_invoices << Factory.generate_invoice( client, 300.00, :issued_on => (DateTime.now << 2), :is_published => true )
    unpaid_invoices << Factory.generate_invoice( client, 400.00, :issued_on => (DateTime.now << 1), :is_published => true )
    
    # This is a basic test in an obvious and typical scenario. Note that we should be matching payments up when they equal invoices..
    Factory.generate_payment client, 202.00

    client_unpaid_invoices = client.unpaid_invoices
    
    assert_equal client_unpaid_invoices.length, unpaid_invoices.length
    client_unpaid_invoices.each{ |inv| assert unpaid_invoices.collect{|un_inv| un_inv.id}.include?(inv.id) }
    
    # Now we test a half payment, which shouldn't make a difference in what's marked as fully-paid:
    Factory.generate_payment client, 99.00

    client_unpaid_invoices = client.unpaid_invoices
    
    assert_equal client_unpaid_invoices.length, unpaid_invoices.length
    client_unpaid_invoices.each{ |inv| assert unpaid_invoices.collect{|un_inv| un_inv.id}.include?(inv.id) }
    
    # Delete all the invoices we just created:
    (paid_invoices+unpaid_invoices).reject!{|inv| inv.delete }
    paid_invoices, unpaid_invoices = [], [] 
    
    # Now try this for the case of a payment created before the invoices...
    Factory.generate_payment client, 23.00

    paid_invoices   << Factory.generate_invoice( client, 8.00, :issued_on => (DateTime.now << 4), :is_published => true )
    paid_invoices   << Factory.generate_invoice( client, 14.00, :issued_on => (DateTime.now << 4), :is_published => true )
    unpaid_invoices << Factory.generate_invoice( client, 30.00, :issued_on => (DateTime.now << 1), :is_published => true )
    unpaid_invoices << Factory.generate_invoice( client, 2.00, :issued_on => (DateTime.now << 1), :is_published => true )

    client_unpaid_invoices = client.unpaid_invoices
    
    assert_equal client_unpaid_invoices.uniq.length, client_unpaid_invoices.length
    client_unpaid_invoices.each{ |inv| assert unpaid_invoices.collect{|un_inv| un_inv.id}.include?(inv.id) }
  end
  
  def test_basic_unassigned_payments
    # TODO: this should be very simlar to test_basic_unpaid_invoices
  end

  def test_recommend_payment_assignments_for
    # TODO: make sure the assignments make sense (equal value outstanding returned before any-outstanding)
  end
  
  def test_recommend_invoice_assignments_for 
    # TODO: make sure the assignments make sense (equal value outstanding returned before any-outstanding)  
  end
end
