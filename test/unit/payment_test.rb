require File.dirname(__FILE__) + '/../test_helper'

module Factory

  def self.generate_invoice(total, attributes = {})
    client = Factory.client
    
    attributes[:issued_on] ||= Time.now
    
    activity_increments = (total.floor).to_f/10
    
    1.upto(10) do |i|
      activity_amount = activity_increments
      activity_amount += total - total.floor if i == 1 
      
      # Tax-related test adjustments:
      activity_tax = (activity_amount * 0.25).floor
      activity_cost = activity_amount-activity_tax

      a = Activity::Adjustment.new :label => 'test invoice'
      a.activity.cost = activity_cost
      a.activity.tax = activity_tax
      a.activity.client = client
      a.activity.occurred_on = (attributes[:issued_on] - 1.months)
      a.activity.is_published = true
      a.save!
    end

    Invoice.create!( { :client => client, :activity_types =>  ActivityType.find(:all) }.merge(attributes) )
  end
  
  def self.generate_payment(amount, attributes = {})
    Payment.create!(
      {
      :amount => amount,
      :client => Factory.client, 
      :payment_method_id => 1
      }.merge(attributes)
    )
  end
  
  def self.client(attributes = {})
    company_name = (attributes.has_key?(:company_name)) ? attributes[:company_name] : 'ACME Fireworks'
    
    client = Client.find :first, :conditions => ['company_name = ?', company_name]
    
    (client) ? client : Client.create!(
      {
      :company_name => company_name,
      :address1     => '470 S. Andrews Ave.',
      :address2     => 'Suite 206', 
      :phone_number => '954-942-7703',
      :fax_number   => '954-942-7933' 
      }.merge(attributes)
    )
  end
  
end

class PaymentTest < ActiveSupport::TestCase

  fixtures :activity_types

  def test_payment_allocations
    client = Factory.client

    invoices = []
    
    [1200.00, 400, 99.99, 1500.99, 430.01].each do |amt| 
      inv =  Factory.generate_invoice(amt)
      
      assert_equal amt, inv.amount # THis was a weird bug we were having so I put this here...
      
      invoices << inv
    end

    assert_equal 3630.99, client.balance
    
    payments = []
    
    [1200.00, 400.00, 99.99, 0.99, 1500, 400.0, 30.01].each do |amt|
      payments << Factory.generate_payment(amt)
    end
    
    assert_equal 0.to_money, client.balance
    
    payments.delete_at(1).destroy
    
    assert_equal 400.00.to_money, client.balance
    
    invoices.each_index { |i| assert_equal( ((i == 1) ? false : true), invoices[i].is_paid? ) }
    
    payments << Factory.generate_payment(174.00)
    payments << Factory.generate_payment(15.00)
    payments << Factory.generate_payment(10.00)
    payments << Factory.generate_payment(201.00)
    
    assert_equal 0.0.to_money, client.balance
    
    assert_equal true, invoices[1].is_paid?
    
    payments << Factory.generate_payment(300.20)
    
    assert_equal -300.20.to_money, client.balance

    invoices << Factory.generate_invoice(300.20)
    
    assert_equal 0.to_money, client.balance
  end
  
  def test_invoice_allocates_payment_credits
    client = Factory.client

    Factory.generate_payment 230.00
    Factory.generate_payment 70.00
    
    invoice_one = Factory.generate_invoice 290.00, :is_published => true

    assert_equal true, invoice_one.is_paid? 
    assert_equal -10.00, client.balance
    
    Factory.generate_payment 200.00
    
    invoice_two = Factory.generate_invoice 220.00, :is_published => true

    assert_equal false, invoice_two.is_paid?
    assert_equal 10.00, client.balance
    
    Factory.generate_payment 10.00
    
    assert_equal true, invoice_two.is_paid?
    assert_equal 0.00, client.balance
    
    Factory.generate_payment 300.00
    
    invoice_three = Factory.generate_invoice 300.00, :is_published => true
    
    assert_equal true, invoice_three.is_paid?
    assert_equal 0.00, client.balance
  end

  def test_invoice_paid_on
    payment_one_on =  sanitize_time(Time.now - 3.months)
    payment_two_on =  sanitize_time(Time.now - 2.months)
    payment_three_on =  sanitize_time(Time.now - 2.months)
    
    Factory.generate_payment 200.00, :paid_on => payment_one_on

    invoice = Factory.generate_invoice 600.00, :issued_on => payment_two_on,  :is_published => true
    
    payment_two = Factory.generate_payment 200.00, :paid_on => payment_two_on
    Factory.generate_payment 200.00, :paid_on => payment_three_on

    assert_equal true, invoice.is_paid?
    assert_equal payment_two_on, invoice.paid_on
    
    payment_two.destroy
    
    assert_equal false, invoice.is_paid?
    assert_equal nil, invoice.paid_on
  end
  
  def test_whacko_payment_deletes
    running_time = sanitize_time(Time.now - 1.years)
    
    payments = []
    invoices = []
    
    [2,4,8,16,32,64,128,256,512,1024].each do |amt|
      invoice = Factory.generate_invoice( amt, :issued_on => (running_time += 2.weeks) )
      payments << Factory.generate_payment( amt, :paid_on => (running_time += 2.weeks) )
      
      assert_equal running_time, invoice.paid_on
      invoices << invoice
    end
    
    assert_equal 0.to_money, Factory.client.balance
    
    [9,7,5,3,1].each { |i| payments.delete_at(i).destroy }
    
    assert_equal 1364.to_money, Factory.client.balance

    [1,3,5,7,9].each do |i|
      running_time += 2.weeks
      payments << Factory.generate_payment( invoices[i].amount, :paid_on => running_time )

      assert_equal true, invoices[i].is_paid?
      assert_equal running_time, invoices[i].paid_on
    end
    
    assert_equal 0.to_money, Factory.client.balance

    5.times { payments.delete_at(0).destroy }
    
    assert_equal 682.to_money, Factory.client.balance
    
    Factory.generate_payment 682, :paid_on => (running_time += 2.weeks) 
    
    [0,2,4,6,8].each { |i| assert_equal running_time, invoices[i].paid_on }
    
    assert_equal 0.to_money, Factory.client.balance
  end

  private
  
  def sanitize_time(time)
    # This removes the usec's 
    Time.utc time.sec, time.min, time.hour, time.day, time.month, time.year, time.wday, time.yday, time.isdst, time.gmt_offset unless time.nil?
  end

end
