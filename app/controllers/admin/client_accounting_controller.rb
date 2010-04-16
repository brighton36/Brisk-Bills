class Admin::ClientAccountingController < ApplicationController
  include AdminLayoutHelper
  include ExtensibleObjectHelper

  active_scaffold :client_accounting do |config|
    config.label = "Accounts Ledger"
    
    config.create.link = nil
    config.update.link = nil
    config.delete.link = nil

    config.columns = [:company_name, :address1, :address2, :city, :state, :zip, :phone_number, :fax_number, :is_active, :uninvoiced_activities_balance, :balance, :created_at, :updated_at]
    
    config.columns[:balance].label = 'Outstanding Balance'
    
    config.columns[:is_active].label = 'Active?'
    
    config.list.columns = [:company_name, :uninvoiced_activities_balance, :balance]
    
    config.columns[:uninvoiced_activities_balance].label = 'Unposted Activity'
    config.columns[:uninvoiced_activities_balance].sort_by :sql => 'uninvoiced_activities_balance_in_cents'

    config.columns[:balance].sort_by :sql => 'balance_in_cents'
    
    config.list.sorting = [{:company_name => :asc}]

    config.create.columns = [:company_name, :address1, :address2, :city, :state, :zip, :phone_number, :fax_number ]
    config.update.columns = [:company_name, :address1, :address2, :city, :state, :zip, :phone_number, :fax_number, :is_active]

    config.nested.add_link "Invoices", [:invoices]
    config.nested.add_link "Payments", [:payments]
    config.nested.add_link "Labor Rates", [:employee_client_labor_rates]
    config.nested.add_link "Transactions", [:client_financial_transactions]
    
    config.full_list_refresh_on = [:update, :destroy]

  end
  
  def self.active_scaffold_controller_for(klass)
    # A hack since there's a view in use on this controller
    (klass == Invoice) ? Admin::InvoicesController : super(klass)
  end
  
  def conditions_for_collection
    ['is_active = ?', true]
  end
  
  handle_extensions
end
