class EmployeeClientLaborRate < ActiveRecord::Base
  include MoneyModelHelper
  
  belongs_to :client
  belongs_to :employee
  
  validates_presence_of :client_id
  validates_presence_of :employee_id  
  
  validates_numericality_of :hourly_rate, :greater_than_or_equal_to => 0, :message => "is not a valid monetary amount"
  
  validates_uniqueness_of :employee_id, :scope => :client_id, :message => "/ Client relationship is already defined"
  
  money :hourly_rate,  :currency => false
  
  def label
    "%s : %s" % [self.employee.name,self.client.name]
  end
  
end