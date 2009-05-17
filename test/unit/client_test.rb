require File.dirname(__FILE__) + '/../test_helper'

class ClientTest < ActiveSupport::TestCase
  fixtures :clients

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
end
