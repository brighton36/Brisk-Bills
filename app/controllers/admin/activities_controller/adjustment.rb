class Admin::ActivitiesController

  activities_scaffold_config do |config|
    %w( client_id label cost tax comments ).each do |field|
      model_field = field.to_sym
      
      config.columns.add model_field
      
      config.columns[model_field].for_activities << 'adjustment'
      
      config.update.columns << model_field
    end
  end
  
  handle_extensions
end