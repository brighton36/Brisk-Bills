module ActiveScaffoldFullRefreshControllerHelpers
  
  # This was introduced to fix bugs that cropped up on the newer versions of active_scaffold
  # specifically, the _list_pagination_links.html.erb doesn't specify the action to the page
  # links, which then default to :update or :create, and paging fails. This fixes that.
  # Really, a less-hackish fix would be to replace the erb file itself. But that wouldn't 
  # be as easily distributable as a plugin
  def params_for_with_refresh(options = {})

    options[:action] = :list if (
      options.length == 0 && 
      active_scaffold_config.full_list_refresh_on.try(:include?, params[:action].to_sym)
    )

    params_for_without_refresh options
  end

   def self.append_features(base)
    super
    base.class_eval do 
      unless method_defined? :active_scaffold_params_for_without_refresh
        alias params_for_without_refresh params_for
        alias params_for params_for_with_refresh
      end
      
    end
  end
end

module ActiveScaffoldFullRefresh
  def action_with_full_refresh
    refresh_on = (active_scaffold_config.full_list_refresh_on or [])
    on_action = params[:action].to_sym

    if refresh_on.include?(on_action) and request.format == 'application/javascript'
      send "do_#{on_action}"

      if successful?
        do_list unless @records
      
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
        render(:update) do |page|
          page.replace_html element_form_id(:action => :update), :partial => 'update_form', :layout => false
        end
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
