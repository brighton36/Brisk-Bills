class Admin::EmployeeClientLaborRatesController < ApplicationController

  include AdminLayoutHelper
  include ExtensibleObjectHelper

  active_scaffold :employee_client_labor_rate do |config|
    config.label = "Employee/Client Labor Rates"

    config.columns = [:client, :employee, :hourly_rate, :created_at, :updated_at]
    
    config.columns[:client].form_ui = :select
    columns[:client].sort_by :sql => 'clients.company_name'

    config.columns[:employee].form_ui = :select
    columns[:employee].sort_by :sql => 'last_name ASC, first_name ASC'

    config.columns[:hourly_rate].sort_by :sql => 'hourly_rate_in_cents'

    config.list.columns = [:client, :employee, :hourly_rate ]
    
    config.create.columns = config.update.columns = [:client, :employee, :hourly_rate]  
    config.list.sorting = [{:hourly_rate => :asc}]
  end
  
  def conditions_for_collection
    ['employees.is_active = ?', true]
  end
  
  handle_extensions
end
