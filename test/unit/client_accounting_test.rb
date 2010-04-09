require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_unit_factory_helper.rb'

class ClientAccountingTest < ActiveSupport::TestCase

  fixtures :activity_types # NOTE : Be sure to incude this when workign with invoices!

  def setup
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    
    Factory.create_client
  end

  def test_eager_attributes

    client = Factory.create_client
 
    [1200.00, 400, 99.99, 1500.99, 430.01].each{|amt| Factory.generate_invoice(amt, :client => client) }

puts ClientAccounting.find(:all).inspect
    # The second assertion is the one we're really here to test ...
    assert_equal 3630.99.to_money, client.balance
    assert_equal 3630.99.to_money, ClientAccounting.find(client.id).balance

    [1200.00, 400.00, 99.99, 0.99, 1500, 50].each { |amt| Factory.generate_payment(amt, :client => client) }
    
    assert_equal 380.01.to_money, client.balance
    assert_equal 380.01.to_money, ClientAccounting.find(client.id).balance

    # Notably - balance & uninvoiced_activities_balance
    
#    puts ClientAccounting.find(:all).inspect
#    acme = Client.create! :company_name => 'ACME Inc.'
#
#    base_clients = ["DeRose Design Consultants, Inc.", "Ashbritt Environmental, Inc.", "CC1 Companies, Inc.", "Academy Roofing", "Affordable Air", "B'nai Congregation", "CC1 Companies, Inc.", "Worldwide Super Abrasives", "Chase Entertainment", "Flying Chimp Media", "GSA", "Lighting Dynamics, Inc.", "Noble Residence", "Garcia Architect", "Scott Rovenger PA", "SarSam", "Gary Slopey", "Thompkins Residence", "United Steel Building"]
#
#    assert_equal base_clients+["ACME Inc."], Client.find_active(:all).collect{|e| e.company_name}
#
#    acme.is_active = false
#    acme.save!
#
#    assert_equal base_clients, Client.find_active(:all).collect{|e| e.company_name}
#
#    assert_equal base_clients, Client.find_active(:all, :conditions => ['id > ?', 0]).collect{|e| e.company_name}
#
#    assert_equal base_clients, Client.find_active(:all, :conditions => 'id > 0').collect{|e| e.company_name}
#
#    assert_equal base_clients, Client.find_active(:all, :conditions => ['id > 0']).collect{|e| e.company_name}
  end
end
