class Admin::ActivitiesController
  activities_scaffold_config do |config|
    %w( proposed_on client_id label cost tax comments ).each do |field|
      model_field = field.to_sym

      config.columns.add model_field
      config.columns[model_field].for_activities << 'proposal'
      config.update.columns << model_field
    end
    
    config.update.columns.move_column_under :proposed_on, :occurred_on
  end
    
  handle_extensions
end