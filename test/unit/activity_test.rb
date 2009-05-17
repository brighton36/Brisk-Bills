require File.dirname(__FILE__) + '/../test_helper'

class ActivityTest < ActiveSupport::TestCase
  fixtures :activities, :clients
  
  def test_activity_constraints
    
    assert_raise( ActiveRecord::RecordInvalid ) do
      Activity.create(
      :is_published => false,
      :occurred_on => Time.new,
      :cost => 0
      ).save!
    end
    
    assert_raise( ActiveRecord::RecordInvalid ) do
      Activity.create(
      :is_published => false,
      :occurred_on => Time.new,
      :activity_type => '',
      :cost => 0
      ).save!
    end
    
    assert_raise( ActiveRecord::RecordInvalid ) do
      Activity.create(
      :is_published => false,
      :occurred_on => Time.new,
      :activity_type => 'n/a',
      :cost => 'Bogus!'
      ).save!
    end
    
    assert_nothing_raised do
      Activity.create(
      :is_published => false,
      :occurred_on => Time.new,
      :activity_type => 'n/a',
      :cost => 6.66
      ).save!
    end
    
    assert_nothing_raised do
      Activity.create(
      :is_published => false,
      :occurred_on => Time.new,
      :activity_type => 'n/a',
      :cost => 0
      ).save!
    end
    
     assert_nothing_raised do
      Activity.create(
      :is_published => false,
      :occurred_on => Time.new,
      :activity_type => 'n/a',
      :client_id => 1,
      :cost => nil
      ).save!
    end
    
    assert_nothing_raised do
      ddc = Client.find :first, :conditions => [ "company_name = ?","DeRose Design Consultants, Inc."]
      
      a1 = Activity.create(
        :is_published => false,
        :occurred_on => Time.new,
        :activity_type => 'n/a',
        :cost => nil
      )
      
      a1.client = ddc
      a1.save!
      
      a2 = Activity.find a1.id, :include => [:client]
      
      assert_equal a2.client_id, ddc.id
    end
    
  end
  
  def test_validations
    a1 = Activity.new :activity_type => nil, :cost => 'abc'
    
    assert_nothing_raised { a1.valid? }
    
    assert_equal 2, a1.errors.length
    assert_equal true, a1.errors.invalid?(:activity_type)
    assert_equal true, a1.errors.invalid?(:cost)
  end
end
