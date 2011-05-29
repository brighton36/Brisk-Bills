module Admin::EmployeeClientLaborRatesHelper

  def employee_client_labor_rate_hourly_rate_column(record)
    h "$%0.2f" % record.hourly_rate
  end
  
  def employee_client_labor_rate_hourly_rate_form_column(record, options)
    text_field_tag options[:name], "%0.2f" % ((@record.hourly_rate) ? @record.hourly_rate : 0), :size => 10, :id => 'record_hourly_rate'
  end
  
  def employee_client_labor_rate_employee_form_column(record, options)
    unavail_clients = nil
    
    if record.client_id
      clr_conditions = ['client_id = ?',record.client_id] 
      
      if record.employee_id
        clr_conditions[0] << ' AND employee_id != ?' 
        clr_conditions << record.employee_id
      end
      
      unavail_clients = EmployeeClientLaborRate.find( 
        :all,
        :select => 'employee_id',
        :conditions => clr_conditions
      ).collect { |clr| "(id != %d)" % clr.employee_id }
    end
  
    select_tag(
      options[:name], 
      options_for_select(
        (Employee.find_active(
          :all, 
          :select => 'id, first_name, last_name', 
          :conditions => (!unavail_clients.nil? and unavail_clients.length > 0) ? "(%s)" % unavail_clients.join(' AND ') : nil,
          :order => 'last_name ASC, last_name ASC'
        ).collect {|e| [ e.name, e.id ] })+[['(Select Employee)',nil]],
        record.employee_id
      ),
      {:id => 'record_employee'}
    )
  end
  
  def employee_client_labor_rate_client_form_column(record, options)
    unavail_emps = nil
    
    if record.employee_id
      clr_conditions = ['employee_id = ?',record.employee_id] 
      
      if record.client_id
        clr_conditions[0] << ' AND client_id != ?' 
        clr_conditions << record.client_id
      end
      
      unavail_emps = EmployeeClientLaborRate.find( 
        :all,
        :select => 'client_id',
        :conditions => clr_conditions
      ).collect { |clr| "(id != %d)" % clr.client_id }
    end
  
    select_tag(
      options[:name], 
      options_for_select(
        (Client.find(
          :all, 
          :select => 'id, company_name', 
          :conditions => (!unavail_emps.nil? and unavail_emps.length > 0) ? "(%s)" % unavail_emps.join(' AND ') : nil,
          :order => 'company_name ASC'
        ).collect {|c| [ c.company_name, c.id ] })+[['(Select Client)',nil]],
        record.client_id
      ),
      {:id => 'record_client'}
    )
  end
  
end
