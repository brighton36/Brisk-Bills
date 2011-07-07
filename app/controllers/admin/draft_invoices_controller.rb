class Admin::DraftInvoicesController < Admin::InvoicesController
  include Admin::DraftInvoicesHelper

  @invoices_scaffold_config = superclass.instance_variable_get('@invoices_scaffold_config').dup

  invoices_scaffold_config do |config|
    config.label = "Draft Invoices"
    
    config.list.columns.instance_eval do 
      @set.delete(:is_published)
      @set.delete(:is_paid?)
    end

    config.action_links.add :batch_create, :label  => 'Batch Create'
  end
  
  def conditions_for_collection
    ['is_published = ?', false]
  end 

  # TODO: Put in a plugin-helper
  # We need to be sure the view is looking in the right place, this little hack should do it:
  def self.active_scaffold_paths
    ret = super
    ret <<  BRISKBILLS_ROOT+'/app/views/admin/invoices'
    ret
  end
  # /TODO: Put in a plugin-helper
  
  def batch_create_on_date_change
    # This is kind of an annoying way to make a date ...
    @invoice_date_at = utc_date_from_param(
      params[:batch_invoice_date_at]
    ) if params[:batch_invoice_date_at]
logger.error "Well?" + @invoice_date_at.inspect

    # I didn't really feel the need to create a partial just for this one line:
    render :inline => '<%= batch_create_clients_form_column(@invoice_date_at) %>' if @invoice_date_at
  end

  def batch_create
    if params.has_key? :batch_client
      invoiceable_client_ids = params[:batch_client].keys.collect(&:to_i)

      if invoiceable_client_ids.length > 0
        all_activity_types = ActivityType.find(:all)

        invoice_date = utc_date_from_param params[:batch_invoice_date_at]
        
        @new_invoices = Client.find(
          :all, 
          :conditions => ['id IN (?)', invoiceable_client_ids]
        ).each do |client|  
          Invoice.create!(
            :client => client, 
            :activity_types => all_activity_types,
            :issued_on => invoice_date,
            :activities => Invoice.recommended_activities_for( 
              client.id, 
              invoice_date, 
              all_activity_types 
            )
          )
        end

        do_list
      end

      render :action => 'batch_create.js'
    else
      @invoice_date_at = Time.utc(*Time.now.to_a).prev_month.end_of_month
      render :action => 'batch_create.html', :layout => false
    end
  end

  private 
  
  def utc_date_from_param(date_hash)
    Time.utc(
      date_hash[:year].to_i, 
      date_hash[:month].to_i, 
      date_hash[:day].to_i,
      date_hash[:hour].to_i,
      date_hash[:minute].to_i,
      date_hash[:second].to_i
    )
  end

  handle_extensions
  
  invoices_scaffold_init
end
