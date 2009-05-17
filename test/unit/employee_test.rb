require File.dirname(__FILE__) + '/../test_helper'

class EmployeeTest < ActiveSupport::TestCase
  fixtures :employees,:credentials

  def test_is_active  
    jsmith = Employee.create! :first_name => 'John', :last_name => 'Smith', :email_address => 'jsmith@test.com'
    
    base_employees = ["Chris DeRose", "Arian Amador", "Michael Bogle"]
    
    assert_equal base_employees+["John Smith"], Employee.find_active(:all).collect{|e| e.name}
    
    jsmith.is_active = false
    jsmith.save!
    
    assert_equal base_employees, Employee.find_active(:all).collect{|e| e.name}
    
    assert_equal base_employees, Employee.find_active(:all, :conditions => ['id > ?', 0]).collect{|e| e.name}
    
    assert_equal base_employees, Employee.find_active(:all, :conditions => 'id > 0').collect{|e| e.name}
    
    assert_equal base_employees, Employee.find_active(:all, :conditions => ['id > 0']).collect{|e| e.name}
    
  end
end
