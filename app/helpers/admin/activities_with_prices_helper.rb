module Admin::ActivitiesWithPricesHelper

  def render_action_link(link, url_options, record)
    return super(link, url_options, record) unless link.action == 'move_to_invoice'

    url_for_dialog = url_for( 
      :controller => url_options[:controller],
      :action => link.action, 
      :eid => url_options[:eid],
      :id => url_options[:id]
    )

    link_to_function link.label, "Modalbox.show('#{url_for_dialog}', {title: 'Move Activity to Invoice ...', width: 700}); return false;"
  end
  
  
end
