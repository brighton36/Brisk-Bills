class Admin::LaborsController < ApplicationController
  
  include AdminLayoutHelper
  include ExtensibleObjectHelper
  include Admin::ActivityTypeControllerHelper
   
  active_scaffold "Activity::Labor" do |config|
    add_activity_type_config config, :except_columns => [:tax, :apply_tax]
    
    config.label = "Labor"

    config.columns << [:comments, :created_at, :updated_at]

    config.columns << :duration
    config.columns[:duration].description = '1h 15m, 1:15, 1 15'
    config.columns[:duration].sort_by :sql => "activity_labors.minute_duration"

    config.columns << :employee
    config.columns[:employee].sort_by :sql => "CONCAT("+
      %w( employees.first_name employees.last_name).collect(){|f| "IF(%s IS NULL, '', %s)" % [f,f]}.join(',')+
    ")"
    config.columns[:employee].form_ui = :select
    
    [config.update, config.create].each do |crud_config|
      crud_config.columns.add_subgroup('Labor'){ |g| g.add [:employee, :duration, :comments] }
    end
    
    config.list.columns = [:occurred_on,:employee, :client, :comments, :duration, :cost]
    config.show.columns = [ :occurred_on,:is_published, :client, :employee, :cost,  :duration, :comments,:updated_at, :created_at ]
  end

  observe_active_scaffold_form_fields :fields => %w(cost employee client duration), :action => :on_labor_observation
  
  def on_labor_observation
    # This got really complicated. Oh well, refactoring most of this in the model would be kind of cool...
    
    record_id = (/^[\d]+$/.match(params[:record_id])) ? params[:record_id].to_i : nil
    labor_before = (record_id.nil?) ? Activity::Labor.new : Activity::Labor.find(record_id)

    labor_after = labor_before.clone 

    labor_after.duration = params[:duration]
    labor_after.comments = params[:comments]
    labor_after.employee_id = params[:employee]
    labor_after.activity.client_id = params[:client]
    labor_after.activity.cost = params[:cost]

    observed_column = params[:observed_column]
    
    allowed_error_fields = /^(employee|client|employee_id|client_id)$/

    render(:update) do |page|
      
      updated_cost = nil
      updated_duration = nil
      auto_cost = nil
      
      # See if we can figure out a good automatic cost:
      if labor_after.employee and labor_after.activity.client
        labor_rate = labor_after.employee.labor_rate_for labor_after.activity.client

        auto_cost = labor_after.minute_duration.to_f/60*labor_rate.hourly_rate.to_f if !labor_rate.nil? and !labor_rate.hourly_rate.nil? and !labor_after.minute_duration.nil?
      end

      # Win or lose, we probably want to do this, (its possible, they change the value from the existing 0:30 to 30m):
      updated_duration = labor_after.clock_duration

      if labor_after.valid?
        if observed_column == 'cost'
          # This means they manually changed the cost themselves
          updated_cost = labor_after.cost
        elsif !auto_cost.nil?
          # Something else changed - let's update the auto-calc price
          updated_cost = auto_cost unless auto_cost.nil?
        end

      else
        page["record_#{observed_column}_#{record_id}"].focus if (
          !allowed_error_fields.match( observed_column ) and
          labor_after.errors.invalid?( observed_column )
        )

        labor_after.errors.each do |attr,msg|
          page.visual_effect( 
            :highlight, 
            "record_#{attr}_#{record_id}", 
            :duration => 3, 
            :startcolor => "#FF0000"
          ) unless allowed_error_fields.match attr
        end

        updated_duration = labor_before.clock_duration if labor_after.errors.invalid? :duration
        updated_cost = (auto_cost.nil?) ? labor_after.cost : auto_cost
      end

      page["record_cost_#{record_id}"].value = to_money(updated_cost) unless updated_cost.nil?
      page["record_duration_#{record_id}"].value = updated_duration unless updated_duration.nil?
    end

  end

  handle_extensions
end
