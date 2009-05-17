class SlimtimerTimeEntry < ActiveRecord::Base
  belongs_to :employee_slimtimer, :class_name => 'Employee::Slimtimer'
  
  belongs_to :slimtimer_task, :class_name => 'SlimtimerTask'
  
  belongs_to :labor, :class_name => 'Activity::Labor', :foreign_key => :activity_labor_id
  
  def label
    trimmed_comments = comments.tr "\r\n", ''
    
    '%s (%s) %s "%s"' % [
      start_time.strftime('%m/%d/%y %I:%M%P'),
      friendly_duration,
      (slimtimer_task.nil?) ? '(Unknown)' : slimtimer_task.name,
      (trimmed_comments.length > 75) ? trimmed_comments[0...47]+'...' : trimmed_comments
    ]
  end
  
  before_create do |t_e|
    create_labor(t_e)
  end

  after_create do |t_e|
    t_e.labor.activity.occurred_on = t_e.start_time
    t_e.labor.activity.save!
  end

  before_update do |t_e|    
    create_labor(t_e) if t_e.labor.nil? or t_e.labor.activity.nil?

    raise StandardError,"Can't commit time_entry change to already published activity." if t_e.labor.activity.is_published == true
    
    t_e.labor.comments = t_e.comments
    t_e.labor.minute_duration = ((t_e.end_time.to_f-t_e.start_time.to_f)/60).round
    t_e.labor.save!
      
    t_e.labor.activity.occurred_on = t_e.start_time
    t_e.labor.activity.save!
  end
  
  def before_destroy
    if labor and labor.activity and labor.activity.is_published  
      raise StandardError,"Can't commit time_entry delete to already published activity." 
    else
      labor.destroy if labor
    end
  end
  
  def self.create_labor(t_e)
    t_e.labor = Activity::Labor.create(
      :employee_id => (t_e.employee_slimtimer.nil?) ? nil : t_e.employee_slimtimer.employee_id,
      :comments    => t_e.comments,
      :minute_duration => ((t_e.end_time.to_f-t_e.start_time.to_f)/60).round
    ) if t_e.labor.nil?
  end
  
  def friendly_duration
    duration_min = (end_time - start_time)/60
    
    hour_part = (duration_min / 60).floor
    min_part  = (duration_min % 60).round
   
    (hour_part > 0) ? "%dhr %dmin" % [hour_part, min_part] : "#{min_part}min"
    
    rescue
      ""
  end
  
end
