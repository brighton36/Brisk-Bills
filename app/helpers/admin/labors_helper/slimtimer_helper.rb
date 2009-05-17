module Admin::LaborsHelper
  
  def slimtimer_task_form_column(record, input_name)
    begin
      slimtimer_task_name = @record.slimtimer_time_entry.slimtimer_task.name
    rescue
      slimtimer_task_name = 'None'
    end
    
    '<span class="slimtimer_task">('+h(slimtimer_task_name)+')</span>'
  end
  
end