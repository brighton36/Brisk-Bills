require File.dirname(__FILE__) + '/../test_helper'

class SlimtimerTimeEntryTest < ActiveSupport::TestCase
  fixtures :employees, :employee_slimtimers, :credentials

  def test_basics
    chris = Employee.find 1
    assert_not_nil chris
      
    ste = nil
    
    # Create
    assert_nothing_raised do

      start_time = Time.local 1982, 1, 4, 1, 0, 0 ,0
      end_time   = start_time+3600 # plus 1h
      
      acme_lawncare = SlimtimerTask.create :name => 'Acme Lawn Care', :owner_employee_slimtimer_id => chris.slimtimer.id
      assert_not_nil acme_lawncare
      
      ste = SlimtimerTimeEntry.create(
        :employee_slimtimer_id => chris.slimtimer.id,
        :comments => 'Trimmed Palm Trees',
        :tags => 'billable',
        :slimtimer_task => acme_lawncare,
        :start_time => start_time,
        :end_time => end_time
      )
    end
    
    assert_not_nil ste
    assert_not_nil ste.labor
    assert_not_nil ste.labor.activity

    assert_not_nil ste.id
    assert_not_nil ste.labor.id
    assert_not_nil ste.labor.activity.id
    
    assert_equal 'Trimmed Palm Trees', ste.labor.comments
    assert_equal 1, ste.labor.employee_id
    assert_equal 60, ste.labor.minute_duration
    assert_equal Time.local(1982, 1, 4, 1, 0, 0 ,0), ste.labor.activity.occurred_on
    assert_equal 'Acme Lawn Care', ste.slimtimer_task.name
    
    # Test Update

    # We create this here, and reuse it a couple times below b/c thats very convenient, and makes sure nothing has changed:
    assert_acmebio_ste = Proc.new() do |on_ste|
      assert_equal 'Engineered shorter Palm Trees', on_ste.labor.comments
      assert_equal 1, on_ste.labor.employee_id
      assert_equal 30, on_ste.labor.minute_duration
      assert_equal Time.local(1985, 2, 4, 5, 0, 0 ,0), on_ste.labor.activity.occurred_on
      assert_equal 'Acme Bio', on_ste.slimtimer_task.name
    end
    
    assert_nothing_raised do
      start_time = Time.local 1985, 2, 4, 5, 0, 0 ,0
      end_time   = start_time+1800 # plus 30m
      
      acme_bio = SlimtimerTask.create :name => 'Acme Bio', :owner_employee_slimtimer_id => chris.slimtimer.id
      assert_not_nil acme_bio
      
      ste.comments = 'Engineered shorter Palm Trees'
      ste.slimtimer_task = acme_bio
      ste.start_time = start_time
      ste.end_time = end_time
      
      ste.save!
    end
    assert_acmebio_ste.call ste
    
    # Test Re-create on activity Delete
    # NOTE: I decided this shouldnt be happening to begin with, and thus we shouldnt be too smart about fixing it if it happens..
    
    # Test Re-create on labor Delete
    assert_nothing_raised do 
      ste.labor.destroy 
      ste.labor = nil
      
      ste.save!
    end
    assert_acmebio_ste.call ste
    
    # Set is_published and test destroy exceptions on delete, and on update
    ste.labor.activity.is_published = true
    
    ste.labor.comments = "These should cause a raise"
    assert_raise(StandardError) { ste.save! }

    assert_raise(StandardError) { ste.destroy }
  end
  
  def test_on_destroy 

    ste_id = nil
    ste_labor_id = nil
    ste_activity_id = nil
    
    assert_nothing_raised do
      chris = Employee.find 1
      assert_not_nil chris
    
      start_time = Time.local 1999, 12, 31, 11, 59, 0 ,0
      
      acme_hairstyles = SlimtimerTask.create :name => 'Acme Hair Styles', :owner_employee_slimtimer_id => chris.slimtimer.id
      assert_not_nil acme_hairstyles
      
      ste = SlimtimerTimeEntry.create(
        :employee_slimtimer_id => chris.slimtimer.id,
        :comments => 'Cornrolled Head',
        :tags => 'billable',
        :slimtimer_task => acme_hairstyles,
        :start_time => start_time,
        :end_time => start_time+60 # plus 1m
      )
      
      ste_id = ste.id
      ste_labor_id = ste.labor.id
      ste_activity_id = ste.labor.activity.id
      
      ste.destroy
    end
    
    assert_kind_of Integer, ste_id
    assert_kind_of Integer, ste_labor_id
    assert_kind_of Integer, ste_activity_id
    
    assert_raise(ActiveRecord::RecordNotFound) { SlimtimerTimeEntry.find ste_id }
    assert_raise(ActiveRecord::RecordNotFound) { Activity::Labor.find ste_labor_id }
    assert_raise(ActiveRecord::RecordNotFound) { Activity.find ste_activity_id }
  end
end
