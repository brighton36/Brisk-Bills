require 'date'
require 'pathname'
require 'slimtimer4r'

class SlimTimer::Record 
  def sanitize_time(time); Time.utc(*time.to_a); end
end

namespace :brisk_bills do
  desc "Import SlimTimer Entries as Brisk Bills tasks" 
  
  task :slimtimer_import => :environment do   
    sync_from_days_ago, sync_start_days_ago, ignore_tasks = Setting.grab( 
      :slimtimer_sync_from_days_ago, 
      :slimtimer_sync_start_days_ago, 
      :slimtimer_ignore_tasks
    )

    sync_from_days_ago = sync_from_days_ago.to_i
    sync_start_days_ago = sync_start_days_ago.to_i
    ignore_tasks = ignore_tasks.to_re # TODO This should likely get moved into the models themselves. And we should import the task - just dont create a corresponding activity

    log_level = :info #:debug

    
    # This will help a bit:
    def model_to_update?( map, st_record, klass )
      st_record_id = st_record.id

      if map.has_key?(st_record_id) and st_record.updated_at.to_a != map[st_record_id].st_updated_at.to_a
        # UPDATE this record:
        return map[st_record_id]
      elsif !map.has_key? st_record_id
        map[st_record_id] = klass.new
        map[st_record_id].id = st_record_id
        
        # CREATE this record:
        return map[st_record_id]
      end
      
      return nil
    end
    
    # Logging Init
    active_record_logger = Logger.new STDERR
    active_record_logger.sev_threshold = (log_level == :debug) ? Logger::DEBUG : Logger::INFO
    ActiveRecord::Base.logger = active_record_logger
    
    # Time to get going
    time_now = Time.new.at_beginning_of_day.ago sync_start_days_ago*24*60*60
    sync_from = time_now.ago sync_from_days_ago*24*60*60
    
    # Cache all the id's and updated dates for the tasks as a quick map...
    tasks_map = {}
    SlimtimerTask.find( :all ).each { |t| tasks_map[t.id] = t }
    
    Employee.find_active( 
      :all, 
      :include => :slimtimer, 
      :conditions => "#{Employee::Slimtimer.table_name}.#{Employee::Slimtimer.primary_key} IS NOT NULL" 
    ).each do |employee|
      begin
        st = SlimTimer.new employee.slimtimer.username, employee.slimtimer.password, employee.slimtimer.api_key, 300
        
        ### Tasks: 
        st.list_tasks('yes').each do |t|
          begin
            # <Record(Result)
            # "name"=>"Charlambliss",
            # "owners"=>[{"name"=>"Arian Amador", "user_id"=>24843, "email"=>"arianamador@gmail.com"}], 
            # "completed_on"=>nil,
            # "updated_at"=>Thu Jan 31 20:28:28 UTC 2008,
            # "tags"=>"", 
            # "role"=>"owner", 
            # "id"=>352968,
            # "reporters"=>[], 
            # "hours"=>0.5,
            # "coworkers"=>[], 
            # "created_at"=>Thu Jan 31 20:28:28 UTC 2008
            # >
            update_task = model_to_update?( tasks_map, t, SlimtimerTask )
        
            # A task needs some updating
            unless update_task.nil?
              update_task[:id] = t.id
              update_task[:name] = t.name
              update_task[:st_updated_at] = t.updated_at
              update_task[:st_created_at] = t.created_at
              update_task[:owner_employee_slimtimer_id] = t.owners[0]['user_id']
    
              puts '%s - %s Task: "%s"' % [ 
                employee.name,
                (update_task.new_record?)?'Creating':'Updating', 
                update_task.label
              ]
              
              update_task.save!
              
              raise StandardError, "Error #{(update_task.new_record?)?'Creat':'Updat'}ing task: #{update_task.errors.full_messages.inspect}" unless update_task.errors.empty?
            end
          
          rescue
            puts "Error in 'list_tasks': #{$!}"
          end
        end
        
        ## Time Entries:
    
        # Let's create an entry update map
        briskbills_time_entries = {}
        employee.slimtimer.time_entries.find(
          :all,
          :conditions => ['start_time >= DATE(?) AND start_time <= DATE(?)', sync_from, time_now ]
        ).each { |t_e| briskbills_time_entries[t_e.id] = t_e }
      
        # We'll end up using this to tell when something's been deleted:    
        st_time_entry_ids = []
    
        st.list_timeentries(sync_from,time_now).each do |e|
          begin
            #  <Record(Result) 
            #  "updated_at"=>Tue Jan 01 20:33:35 UTC 2008, 
            #  "comments"=>"Worked on new revisions for Popups, wishlist, and product finder.", 
            #  "tags"=>"", 
            #  "duration_in_seconds"=>16460, 
            #  "id"=>2336068, 
            #  "task"=>{
            #     "name"=>"Antiquities", 
            #     "owners"=>[{"name"=>"Arian Amador", "user_id"=>24843, "email"=>"arianamador@gmail.com"}],
            #     "completed_on"=>nil, 
            #     "updated_at"=>Fri Nov 30 13:01:35 UTC 2007, 
            #     "tags"=>"billable", 
            #     "role"=>"owner", 
            #     "id"=>273061, 
            #     "reporters"=>[{"email"=>"cderose@derosetechnologies.com"}], 
            #     "hours"=>101.11, 
            #     "coworkers"=>[{"email"=>"cderose@derosetechnologies.com"}], 
            #     "created_at"=>Mon Oct 15 17:14:03 UTC 2007
            #  }, 
            #  "in_progress"=>false,
            #  "created_at"=>Mon Dec 31 22:05:28 UTC 2007, 
            #  "end_time"=>Mon Dec 31 18:03:03 UTC 2007, 
            #  "start_time"=>Mon Dec 31 13:28:43 UTC 2007
            #  >
            st_time_entry_ids << e.id
            
            unless e.in_progress or ignore_tasks.match(e.task.name)
              update_time_entry = model_to_update? briskbills_time_entries, e, SlimtimerTimeEntry
            end
    
            unless update_time_entry.nil?
              update_time_entry[:slimtimer_task_id] = e.task.id
              update_time_entry[:employee_slimtimer_id] = employee.slimtimer.id
              update_time_entry[:comments] = e.comments
              update_time_entry[:tags] = e.tags
              update_time_entry[:start_time] = e.start_time
              update_time_entry[:end_time]   = e.end_time
              update_time_entry[:st_updated_at] = e.updated_at
              update_time_entry[:st_created_at] = e.created_at
    
              puts '%s - %s Time Entry: %s' % [ 
                employee.name,
                (update_time_entry.new_record?)?'Creating':'Updating', 
                update_time_entry.label
              ]
              update_time_entry.save!
              
              raise StandardError, "Error #{(update_time_entry.new_record?)?'Creat':'Updat'}ing time_entry: #{update_time_entry.errors.full_messages.inspect}" unless update_time_entry.errors.empty?
            end
          rescue
            puts "Error in 'list_timeentries': #{$!}"
          end
        end
        
        # Now delete anything thats still dangling in brisk:
        briskbills_time_entries.keys.reject{ |cu_id| st_time_entry_ids.include? cu_id }.each do |te_id|
          begin        
            puts '%s - Deleting Time Entry: %s' % [ 
              employee.name,
              SlimtimerTimeEntry.find(te_id).label
            ]        
            SlimtimerTimeEntry.destroy te_id
          rescue
            puts "Error in 'deleted_time_entry_ids': #{$!}"
          end
        end
    
      
      rescue
        puts "Error in 'Employee.find': #{$!}"
      end
    end

  end
  
end