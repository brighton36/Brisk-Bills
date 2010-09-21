class Admin::EmployeesController < ApplicationController
  include AdminLayoutHelper
  include ExtensibleObjectHelper

  active_scaffold :employee do |config|
    config.label = "Employees"

    config.columns = [:first_name, :last_name, :email_address, :password, :phone_extension, :is_active, :login_enabled, :created_at, :updated_at]
    
    config.columns[:is_active].label = 'Active?'

    config.columns[:email_address].includes = [:credential]
    config.columns[:email_address].sort_by :sql => "credentials.email_address"
    
    config.list.columns =[:last_name, :first_name, :email_address]
    
    config.list.sorting = [{:last_name => :asc}, {:first_name => :asc}]
    
    config.nested.add_link "Labor Rates", [:employee_client_labor_rates]
    
    config.create.columns = [:first_name, :last_name, :email_address, :password, :phone_extension, :login_enabled]
    config.update.columns = [:first_name, :last_name, :email_address, :password, :phone_extension, :is_active, :login_enabled]
    
    config.full_list_refresh_on = [:update, :destroy]
  end
  
  def conditions_for_collection
    ['is_active = ?', true]
  end
 
  handle_extensions
end
