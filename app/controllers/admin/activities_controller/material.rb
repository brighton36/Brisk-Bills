class Admin::ActivitiesController
  include Admin::ActivityTaxControllerHelper
  
  activities_scaffold_config do |config|
    %w( client_id label cost apply_tax tax comments ).each do |field|
      model_field = field.to_sym
      
      config.columns.add model_field
      config.columns[model_field].for_activities << 'material'
      
      config.update.columns << model_field
      
      config.update.columns.move_column_under :apply_tax, :cost
    end
    
    config.columns[:apply_tax].label = "Apply Tax?"
  end 

  handle_extensions
end