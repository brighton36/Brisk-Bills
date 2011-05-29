module Admin::ActivitiesHelper

  def activity_employee_id_form_column(record, input_name)
    select_tag(
      input_name, 
      options_for_select(
        # NOTE: We don't do a find_active here, but see the conditions...
        Employee.find(
          :all, 
          :select => 'id, first_name, last_name', 
          :order => 'last_name ASC, last_name ASC',
          :conditions => ['is_active = ? OR id = ?', true, @record.labor.employee_id]
        ).collect {|e| [ e.name, e.id ] },
        @record.labor.employee_id
      ),
      options_for_column('employee_id')
    )
  end
  
  def activity_duration_form_column(record, input_name)
    text_field_tag input_name, @record.labor.clock_duration, options_for_column('duration').merge({:size => 10})
  end
  
  def activity_comments_form_column(record, input_name)
    text_area_tag input_name, @record.labor.comments, options_for_column('comments').merge({:cols => 72, :rows => 20})
  end
  
end