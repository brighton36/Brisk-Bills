class Admin::AdjustmentsController < ApplicationController
  
  include AdminLayoutHelper
  include ExtensibleObjectHelper
  include Admin::ActivityTypeControllerHelper
  
  active_scaffold "Activity::Adjustment" do |config|
    add_activity_type_config config, :except_columns => [:apply_tax]
    
    config.label = "Adjustments"
    
    %w(update create).each do |crud_action|
      config.send(crud_action).columns.add_subgroup('Adjustment') { |g| g.add [:label, :comments] }
    end
    
    config.columns << [:label, :comments, :created_at, :updated_at]
    config.list.columns = [:occurred_on, :client, :label, :cost, :tax]
    config.show.columns = [ :occurred_on,:is_published, :client, :label, :cost, :tax, :comments, :updated_at, :created_at ]
  end

  handle_extensions
end
