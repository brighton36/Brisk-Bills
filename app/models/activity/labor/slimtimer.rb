class Activity::Labor < ActiveRecord::Base
  has_one :slimtimer_time_entry, :foreign_key => :activity_labor_id, :class_name => "::SlimtimerTimeEntry"
end

Activity.class_eval do

  after_save do |record|
    unless record.labor.nil? or record.labor.slimtimer_time_entry.nil? or record.labor.slimtimer_time_entry.slimtimer_task.nil?
      st_task = record.labor.slimtimer_time_entry.slimtimer_task

      ignore_auto_task, ignore_auto_client = Setting.grab :slimtimer_dont_autoassign_tasks, :slimtimer_dont_autoassign_clients
        
      ignore_auto_task = ignore_auto_task.to_re
      ignore_auto_client = ignore_auto_client.to_re
            
      if (
        !ignore_auto_task.match(st_task.name) and 
        st_task.default_client_id != record.client_id and
        (record.client and !ignore_auto_client.match(record.client.company_name))
      )
        st_task.default_client_id = record.client_id
        st_task.save!
      end
    end
  end

  handle_extensions
end
