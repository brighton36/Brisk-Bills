class Admin::ActivitiesController

  activities_scaffold_config do |config|
    config.columns << :slimtimer_task
    config.columns[:slimtimer_task].label = 'SLIM<em>TIMER</em> Task'
    config.columns[:slimtimer_task].for_activities << 'labor'

    config.update.columns << :slimtimer_task
    config.update.columns.move_column_under :slimtimer_task, :occurred_on
  end

  alias labor_do_edit_without_slimtimer labor_do_edit
  
  def labor_do_edit_with_slimtimer    
    # Here we'll assign a default client to the task if we can ascertain one:
    begin
      @record.client_id = @record.labor.slimtimer_time_entry.slimtimer_task.default_client_id if @record.client_id.nil?
    rescue
      
    end
    
    labor_do_edit_without_slimtimer
  end
  
  alias labor_do_edit labor_do_edit_with_slimtimer

  handle_extensions
end