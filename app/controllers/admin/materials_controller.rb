class Admin::MaterialsController < ApplicationController
  include AdminLayoutHelper
  
  include Admin::ActivityTypeControllerHelper
  include Admin::ActivityTaxControllerHelper
  
  include ExtensibleObjectHelper

  active_scaffold "Activity::Material" do |config|
    add_activity_type_config config
    
    config.label = "Materials"
    
    %w(update create).each do |crud_action|
      config.send(crud_action).columns.add_subgroup('Materials') { |g| g.add [:label, :comments] }
    end
    
    config.columns << [:label, :comments, :created_at, :updated_at]
    config.list.columns = [:occurred_on, :client, :label, :cost, :tax]
    config.show.columns = [ :occurred_on,:is_published, :client, :label, :cost, :tax, :comments, :updated_at, :created_at ]
  end

  handle_extensions
end
