require File.dirname(__FILE__) + '/../../test_helper'

module ActivityTypeTestHelper
  
end  
  
class Activity::LaborTest < ActiveSupport::TestCase
  fixtures :activities, :clients, :employees, :credentials
  
  include ActivityTypeTestHelper
  
  def test_basic_labor
    time_now = Time.new
    
    l = Activity::Labor.new(
      :employee_id => 1,
      :comments => 'Test Labor',
      :minute_duration => 90
    )
    
    assert_not_nil l.activity

    assert_equal true, l.valid?

    l.activity.occurred_on = time_now
    l.activity.cost = 55.34
    l.activity.client_id = 1

    assert_nothing_raised { l.save! }
  
    assert_equal 1, l.employee_id
    assert_equal 'Test Labor', l.comments
    assert_equal 90, l.minute_duration
    
    assert_not_nil l.activity_id
    assert_not_nil l.activity.id
    
    assert_equal l.activity_id, l.activity.id
    assert_equal 'labor', l.activity.activity_type

    assert_equal 1, l.activity.client_id
    assert_equal BigDecimal.new("55.34"), l.activity.cost
    assert_equal time_now, l.activity.occurred_on
    assert_equal false, l.activity.is_published   # Make sure this defaults to false
  end
  
  def test_basic_activity
    abc_liquor = Client.create :company_name => 'ABC Liquor'
    assert_not_nil abc_liquor.id
    
    a = nil
    assert_nothing_raised do
      a = Activity.new :activity_type => 'labor', :client => abc_liquor
      
      a.build_labor :employee => Employee.find(1), :comments => 'Fixed cash register', :minute_duration => 120
      a.save!
    end

    assert_not_nil a.id
    assert_not_nil a.labor.id # Check to make sure the labor was auto-saved during activity save..
    
    assert_equal 'labor', a.activity_type
    assert_equal 'ABC Liquor', a.client.company_name
    assert_equal abc_liquor.id, a.client_id
    assert_equal 1, a.labor.employee_id
    assert_equal 'Fixed cash register', a.labor.comments
    assert_equal 120, a.labor.minute_duration
    
    new_labor_id = a.labor.id
    
    assert_nothing_raised { a.destroy }

    assert_raise(ActiveRecord::RecordNotFound) { Activity::Labor.find new_labor_id }
  end
  
  def test_client_association
    labors = []
    
    ## build_client :
    l1 = nil
    assert_nothing_raised do
      l1 = Activity::Labor.new :employee_id => 1, :comments => 'Acme Motors Tune-up', :minute_duration => 90
    end
    l1.activity.occurred_on = Time.new
    l1.activity.cost = 12.34
    l1.activity.build_client :company_name => "Acme Motors"
    
    labors << l1
    
    assert_nothing_raised { l1.save! }
    
    assert_not_nil l1.activity.id
    assert_not_nil l1.activity.client_id
    assert_equal l1.activity.client_id, l1.client.id
    assert_equal "Acme Motors", l1.client.company_name
    
    ## create_client :
    l2 = nil
    assert_nothing_raised do
      l2 = Activity::Labor.new :employee_id => 1, :comments => 'Unclogged Toilets', :minute_duration => 60
      l2.create_client :company_name => 'Acme Plumbing'
    end
    
    l2.activity.occurred_on = Time.new
    l2.activity.cost = 56.78
    
    labors << l2
    
    assert_not_nil l2.activity.client_id
    assert_equal l2.activity.client_id, l2.client.id
    assert_equal "Acme Plumbing", l2.client.company_name
    
    assert_nothing_raised { l2.save! }
    
    assert_not_nil l2.activity.id
    
    ## client= 
    acme_movers = Client.create :company_name => 'Acme Movers' 
    
    l3 = nil
    assert_nothing_raised do
      l3 = Activity::Labor.new :employee_id => 1, :comments => 'Relocated Piano', :minute_duration => 30
      l3.client = acme_movers
    end
  
    labors << l3
    
    assert_equal l3.activity.client_id, acme_movers.id
    assert_equal l3.activity.client_id, l3.client.id
    assert_equal "Acme Movers", l3.client.company_name
    
    assert_nothing_raised { l3.save! }
    
    assert_not_nil l3.activity.id
    
    # Activity::Labor.create
    acme_pavers = Client.create :company_name => 'Acme Pavers'
    
    l4 = nil
    assert_nothing_raised do
      l4 = Activity::Labor.create :employee => Employee.find(2), :client => acme_pavers, :comments => 'laid tiles', :minute_duration => 15
    end
  
    labors << l4
    
    assert_not_nil l4.activity.id
    assert_equal 2, l4.employee.id
    assert_equal l4.employee_id, l4.employee.id
    
    assert_equal acme_pavers.id, l4.activity.client_id
    assert_equal l4.activity.client_id, l4.client.id
    assert_equal "Acme Pavers", l4.client.company_name
    
    # Test find with include - test the order!
    [ [:client], [:activity,:client], [:client,:activity] ].each do |find_include|
    
      fc_options = { :include => find_include, :conditions => ['clients.company_name REGEXP ?','^Acme .+$'] }
      
      rows = nil
      assert_nothing_raised { rows = Activity::Labor.find :all, fc_options.merge({:order => '`activity_labors`.`created_at` ASC'}) }
      
      assert_equal labors.length, rows.length
      
      labors.each_index {|i| assert_equal rows[i], labors[i] }
      
      # Count test
      assert_equal labors.length, Activity::Labor.count( fc_options )
    end

    # Test Remove
    assert_nothing_raised { l1.client = nil }
    
    assert_nil l1.activity.client_id
  end
  
  def test_association_deletes
    labor = nil
    
    assert_nothing_raised do
      labor = Activity::Labor.create(
        :employee => Employee.find(1),
        :client   => Client.create( :company_name => 'Acme Electrical' ),
        :comments => 'Rewired Garbage Disposal',
        :minute_duration => 15
      )
    end
    
    new_labor_id = labor.id
    new_activity_id = labor.activity.id
    
    assert_nothing_raised { labor.destroy }

    assert_not_nil Employee.find( 1 )
    assert_not_nil Client.find( :first, :conditions => ['company_name = ?', 'Acme Electrical'] )
    
    assert_raise(ActiveRecord::RecordNotFound) { Activity::Labor.find new_labor_id }
    assert_raise(ActiveRecord::RecordNotFound) { Activity.find new_activity_id }
  end
  
  def test_validations
    # Test labor validations that should fail:
    l1 = Activity::Labor.new :employee_id => nil, :minute_duration => 'abc'
    
    assert_nothing_raised { l1.valid? }
    
    assert_equal 2, l1.errors.length
    assert_equal true, l1.errors.invalid?(:minute_duration)
    assert_equal true, l1.errors.invalid?(:employee_id)
    
    # Create labor, then test activity validations that should fail
    l1 = Activity::Labor.new(
      :employee_id => nil,
      :minute_duration => 'abc'
    )

    l2 = Activity::Labor.new :employee_id => Employee.find(1), :minute_duration => 1
    l2.activity.activity_type = nil
    l2.activity.cost = 'abc'
    
    assert_nothing_raised { l2.valid? }

    assert_equal true, l2.errors.invalid?(:cost)
    assert_equal true, l2.errors.invalid?(:activity_type)
    assert_equal 2, l2.errors.length

    # Create activity, call validate, then test that the labor validations fail
    a1 = Activity.new :activity_type => 'labor', :cost => 5
    a1.build_labor :employee_id => nil, :minute_duration => 'abc'

    assert_nothing_raised { a1.valid? }
    
    assert_equal false, a1.errors.invalid?(:base)
    assert_equal nil, a1.errors[:base]

    assert_equal true, a1.errors.invalid?(:minute_duration)
    assert_equal true, a1.errors.invalid?(:employee_id)
  end
  
  def test_duration
    a = Activity::Labor.new :employee_id => Employee.find(1)
    
    { 
    "120"     => 120, "90"    => 90,  "1h 20m"   => 80, 
    "1hr 15m" => 75,  "87m"   => 87,  "1h"       => 60, 
    "5hr"     => 300, "1 45"  => 105, "1:55"     => 115,
    " 2 h "   => 120, "5 hr"  => 300, "1 h 20 m" => 80,
    " 12 m "  => 12, " 1 13 " => 73,  120        => 120,
    "0h"      => 0,   "0"     => 0,   ""         => 0,
    0         => 0
    }.each_pair do |input_min, actual_min|
      assert_nothing_raised{ a.duration = input_min}
      assert_equal actual_min, a.minute_duration
    end
    
    # Test errors now:
    %w( abc 12.5m 1.5h ).each do |bad_duration|
      assert_nothing_raised do
        a.duration = bad_duration
        assert_equal false, a.valid?
      end
      
      assert_equal true, a.errors.invalid?(:duration)
      assert_equal 1, a.errors.length
    end
    
  end
  
  def test_create_defaults
    l = Activity::Labor.create
    
    assert_equal 'labor', l.activity.activity_type
    assert_equal 0, l.minute_duration
    assert_equal nil, l.activity.cost
    assert_equal false, l.is_published

    [ :employee_id, :activity_id, :comments ].each { |f| assert_equal nil, l.send(f) }  
    [ :client_id, :invoice_id, :occurred_on ].each { |f| assert_equal nil, l.activity.send(f) }
  end
  
end
