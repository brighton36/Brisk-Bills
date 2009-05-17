class Admin::ClientsController < ApplicationController
  include AdminLayoutHelper
  include ExtensibleObjectHelper

  active_scaffold :client do |config|
    config.label = "Clients"

    config.columns = [:company_name, :address1, :address2, :city, :state, :zip, :phone_number, :fax_number, :is_active, :created_at, :updated_at]
    
    config.columns[:is_active].label = 'Active?'
    
    config.list.columns = [:company_name,:phone_number, :fax_number ]

    
    config.list.sorting = [{:company_name => :asc}]

    config.create.columns = [:company_name, :address1, :address2, :city, :state, :zip, :phone_number, :fax_number ]
    config.update.columns = [:company_name, :address1, :address2, :city, :state, :zip, :phone_number, :fax_number, :is_active]

    config.nested.add_link "Representatives", [:client_representatives]
    
    config.full_list_refresh_on = [:update, :destroy]
  end
    
  def conditions_for_collection
    ['is_active = ?', true]
  end
 
  
  handle_extensions
end
