class Admin::ActivitiesController

  activities_scaffold_config do |config|
    %w( client_id employee_id duration cost comments ).each do |field|
      model_field = field.to_sym
      
      config.columns.add model_field
      config.columns[model_field].for_activities << 'labor'
      
      config.update.columns << model_field
    end
    
    config.update.columns.move_column_under :employee_id, :client_id
    config.update.columns.move_column_under :duration, :employee_id
    
    config.columns[:duration].description = '1h 15m, 1:15, 1 15'
  end

  observe_active_scaffold_form_fields(
    :fields => %w(cost employee_id client_id duration),
    :action => :on_labor_observation, 
    :for_activities => 'labor'
  )
  
  def on_labor_observation
    # NOTE: THis action is likely performing more SELECTs then is appropriate, particularly regarding the .client and .employee ...
    # THis is kind of nasty in general, would be nice to do more of this in the model...
    
    render :update do |page|
      begin
        raise StandardError, "No record_id provided" unless params.has_key? :record_id and params[:record_id].length > 0
        raise StandardError, "Missing duration" unless params.has_key? :duration
        raise StandardError, "Missing input name" unless params.has_key? :observed_column and params[:observed_column].length > 0
    
        record_id = params[:record_id].to_i
        
        jsid_suffix = (params[:eid]) ? "#{params[:eid]}_#{record_id}" : record_id.to_s
    
        @activity = Activity.find record_id, :include => [:labor]
        
        raise StandardError, "Activity Not Found" if @activity.nil?

        input_name = params[:observed_column].to_sym
        
        @activity.client_id = params[:client_id].to_i if params.has_key? :client_id and params[:client_id].length > 0
        @activity.labor.employee_id = params[:employee_id].to_i if params.has_key? :employee_id and params[:employee_id].length > 0
          
        old_cost = @activity.cost
        
        labor_rate = (@activity.labor.employee and @activity.client) ? @activity.labor.employee.labor_rate_for(@activity.client) : nil

        begin
          record_duration_js_id = "record_duration_#{jsid_suffix}"
          
          old_clock_duration ||= @activity.labor.clock_duration
          old_clock_duration ||= 0

          @activity.labor.duration = params[:duration]

          raise StandardError unless @activity.labor.valid?
          
          page[record_duration_js_id].value = @activity.labor.clock_duration if old_clock_duration != @activity.labor.clock_duration
          
        rescue
            page[record_duration_js_id].value = old_clock_duration
            page[record_duration_js_id].focus
            page.visual_effect :highlight, record_duration_js_id, :duration => 3, :startcolor => "#FF0000"
        end

        record_cost_js_id = "record_cost_#{jsid_suffix}"
        
        if input_name == :cost then
          begin
            raise StandardError unless /^([\d]+|[\d]+\.[\d]{1,2})$/.match(params[:cost])
            new_cost = params[:cost]
          rescue
            page[record_cost_js_id].value = old_clock_duration
            page[record_cost_js_id].focus
            page.visual_effect :highlight, record_cost_js_id, :duration => 3, :startcolor => "#FF0000"
          end
        end

        new_cost ||= @activity.labor.minute_duration.to_f/60*labor_rate.hourly_rate unless labor_rate.nil? or labor_rate.hourly_rate.nil? or @activity.labor.minute_duration.nil?

        page[record_cost_js_id].value = money_for_input new_cost
    
      rescue
        page.alert 'Error updating form Record(%s) "%s"' % [params[:record_id], $!]
      end
    end    
  end

  def labor_do_edit
    begin
      labor_rate = @record.labor.employee.labor_rate_for(@record.client)
      @record.cost = @record.labor.minute_duration.to_f/60*labor_rate.hourly_rate.to_f
    rescue
    end if @record.cost.nil?
    
  end
  
  alias labor_do_update labor_do_edit

  def labor_do_list(records)
    records.each do |record|
      begin
        record.client_id = record.labor.slimtimer_time_entry.slimtimer_task.default_client_id if record.client_id.nil?

        labor_rate = record.labor.employee.labor_rate_for record.client_id
        record.labor.hourly_rate = labor_rate.hourly_rate
      rescue
        # We're just making guesses, if they dont work out, thats totally cool..
      end
      
    end
  end
  
  handle_extensions
end