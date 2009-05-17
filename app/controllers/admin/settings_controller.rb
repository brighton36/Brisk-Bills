class Admin::SettingsController < ApplicationController
  include AdminLayoutHelper
  include ExtensibleObjectHelper

  active_scaffold :setting do |config|
    config.label = "Site Settings"

    config.create.link = nil

    config.columns = [:label, :keyname, :keyval, :description, :created_at, :updated_at]
    
    config.columns[:label].label = 'Setting'
    config.columns[:keyval].label = 'Value'
    
    config.list.columns =[:label, :keyval ]
    
    config.list.sorting = [{:label => :asc}]
    
    config.create.columns = config.update.columns = [:label, :description, :keyval]
  end
  
  handle_extensions
end
