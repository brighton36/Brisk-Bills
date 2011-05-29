module Admin::IsActiveColumnHelper

  # This is for the Client and Employees controller itself:
  def is_active_form_column(record, options)
    input_id = 'record_is_active'

    confirm_prompt = 
      '<div class="warning">'+
        '<p>Are you sure you want to deactive "'+h(record.name)+'" ?</p>'+
        '<input type="button" value="Yes, deactivate!" onclick="Modalbox.hide()" /> or '+
        '<input type="button" value="No, leave it!" onclick="Modalbox.hide();$(\''+input_id+'\').value = \'true\';" />'+
      '</div>'
    
    modalbox_params = { :title => 'Confirm De-activation', :width => 300}

    select_tag(
      options[:name], 
      options_for_select( [ ["Yes", 'true'], ["No", 'false'] ], record.is_active.to_s ),
      :id => input_id
    )+
    observe_field( 
      input_id, 
      :function => "if ($F('#{input_id}')=='false'){ Modalbox.show(#{confirm_prompt.to_json},#{modalbox_params.to_json})}"
    )
  end

  # Helps us to respect the is_active field on the Employee and Client associations
  def association_options_find(association, conditions = nil)
    if  /^(Employee|Client)/.match association.klass.to_s   
      fkey = $1.foreign_key.to_sym

      association_id = (@record.respond_to? :activity and @record.activity.respond_to? fkey) ? 
        @record.activity.send(fkey) : 
        @record.send(fkey)
      
      conditions = controller.send(
        :merge_conditions, 
        conditions, 
        ["is_active = ? OR id = ?", true, association_id]
      )
    end

    super association, conditions
  end

end