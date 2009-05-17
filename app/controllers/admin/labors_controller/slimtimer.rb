class Admin::LaborsController 

  alias edit_without_slimtimer edit
  
  def edit_with_slimtimer
    self.active_scaffold_config.configure do |config|
      config.columns << :slimtimer_task
      config.columns[:slimtimer_task].label = 'SLIM<em>TIMER</em> Task'
      
      # This looks real iffy, but seems to be the best way of doing this... even if its super ugly
      config.update.columns.each do |uc| 
        if uc.label == 'Activity'
          uc.add :slimtimer_task
          uc.move_column_under :slimtimer_task, :occurred_on
        end
      end
    end
    
    # Here we'll fetch a default client if we can ascertain one:
    begin
      @record.activity.client_id = @record.slimtimer_time_entry.slimtimer_task.default_client_id if @record.activity.client_id.nil?
    rescue
      
    end
    
    edit_without_slimtimer
  end
  
  alias edit edit_with_slimtimer
    
end