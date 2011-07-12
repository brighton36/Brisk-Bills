class Admin::ActivitiesWithPricesController < Admin::ActivitiesController

  @activities_scaffold_configs = superclass.instance_variable_get('@activities_scaffold_configs').dup
  
  activities_scaffold_config do |config|
    config.label = "Invoice Activity"
    
    config.columns << [:cost, :tax]
    config.list.columns = [:activity, :tax, :cost, :occurred_on]
        
    config.action_links.add(
      :move_to_invoice, 
      :type => :member, 
      :label => 'Move...', 
      :crud_type => :update, 
      :action => 'move_to_invoice'
    )

    config.columns[:cost].sort_by :sql => 'cost_in_cents'
    config.columns[:tax].sort_by  :sql => 'tax_in_cents'
  end
  
  # This adjusts the order of the link so that move appears to the left:
  def action_links_order
    links = active_scaffold_config.action_links
    links.sort_by{ |l| ( l.action == "move_to_invoice" ) ? -1 : 1 }
  end
  
  # TODO: Put in a plugin-helper?
  # We need to be sure the view is looking in the right place, this little hack should do it:
  def self.active_scaffold_paths
    super_view_path = BRISKBILLS_ROOT+'/app/views/admin/activities'
    @active_scaffold_overrides << super_view_path unless @active_scaffold_overrides.include? super_view_path
    super
  end
  # /TODO

  # This is a little hackish - but it fixes would-be problems with the observation code
  @active_scaffold_observations = superclass.active_scaffold_observations
  
  def move_to_invoice
    @errors_during_move = []
    
    activity = Activity.find params[:id].to_i
    
    dest_conditions = ['invoices.is_published = ?',false]
    dest_conditions[0] += ' AND invoices.id != ?' and dest_conditions << activity.invoice_id if activity
    
    @dest_invoices = Invoice.find_with_totals(
      :all, 
      :conditions => dest_conditions, 
      :order => 'invoices.issued_on DESC, invoices.id DESC', 
      :include => [:client]
    )

    if params.has_key? :move_to_invoice_id
      begin
        invoice_dest = (params[:move_to_invoice_id].empty?) ? 
          nil :
          Invoice.find(params[:move_to_invoice_id].to_i)

        activity.move_to_invoice! invoice_dest

        do_list
        
        flash[:warning]  = (invoice_dest) ? 
          ('%s successfully moved to "%s"' % [activity.label,invoice_dest.long_name]) :
          ('The %s was removed from this invoice.' % activity.label)
      rescue
        @errors_during_move << $!
      end
      
      render :action => 'move_to_invoice.js'
    else
      render :action => 'move_to_invoice.html', :layout => false
    end
  end

  handle_extensions

  activities_scaffold_init
end
