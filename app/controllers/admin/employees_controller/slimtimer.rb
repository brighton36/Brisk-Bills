class Admin::EmployeesController 

  self.active_scaffold_config.configure do |config|
    
    columns_as_symbols = []
     
    %w( username password api_key ).each do |st_field|
      model_field = "slimtimer_#{st_field}".to_sym
      
      config.columns.add model_field
      config.columns[model_field].includes = [:slimtimer]
      config.columns[model_field].sort_by :sql => "employee_slimtimers.#{st_field}"
      config.columns[model_field].label = 'St '+st_field.humanize
      
      columns_as_symbols << model_field
      config.show.columns << model_field
    end
    
    subgroup_title = "<em>SLIM</em>TIMER Settings"
    
    config.create.columns.add_subgroup( subgroup_title ) { |g| g.add( *columns_as_symbols ) }
    config.update.columns.add_subgroup( subgroup_title ) { |g| g.add( *columns_as_symbols ) }
  
    # This seems to enforce the registration of the add_subgroup's
    self.active_scaffold_config._load_action_columns
  end
  
  handle_extensions
end