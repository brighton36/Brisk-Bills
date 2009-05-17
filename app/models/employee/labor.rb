
Employee.class_eval do

  def labor_rate_for(client)
    client_id ||= client.id if client.class.to_s == 'Client'
    client_id ||= client.to_i if client.respond_to? :to_i
    
    raise StandardError, "Invalid Client" if client_id.nil?
    
    EmployeeClientLaborRate.find(:first, :conditions => ['employee_id = ? AND client_id = ?' , self.id , client_id ] )
  end

end