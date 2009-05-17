module ActiveScaffoldFullRefresh
  def action_with_full_refresh
    refresh_on = (active_scaffold_config.full_list_refresh_on or [])
    on_action = params[:action].to_sym

    if refresh_on.include?(on_action) and request.format == 'application/javascript'
      send "do_#{on_action}"

      if successful?
        do_list
      
        render(:update) do |page| 
          page.replace_html active_scaffold_content_id, :partial => 'list', :layout => false
          
          if on_action == :create
            cancel_selector = "##{element_form_id(:action => :create)} a.cancel".to_json
            
            page << ((active_scaffold_config.create.persistent) ? 
              "$$(#{cancel_selector}).first().link.reload();" :
              "$$(#{cancel_selector}).first().link.close();")
          end
        end
      else
        render :action => "#{on_action}.rjs", :layout => false
      end

    else
      send "#{on_action}_without_full_refresh"
    end
  end

  def self.append_features(base)
    super
        
    base.class_eval do
      module_action = /[^\:]+$/.match(base.to_s).to_a[0].downcase
      
      module_action = 'destroy' if module_action == 'delete'
      
      unless method_defined? "#{module_action}_without_full_refresh".to_sym
        alias_method "#{module_action}_without_full_refresh", module_action
        alias_method module_action, :action_with_full_refresh
      end
    end
  end
end