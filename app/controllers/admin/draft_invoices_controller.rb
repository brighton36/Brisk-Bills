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
    @invoice_date_at = Time.utc(
      params[:batch_invoice_date_at][:year].to_i, 
      params[:batch_invoice_date_at][:month].to_i, 
      params[:batch_invoice_date_at][:day].to_i,
      params[:batch_invoice_date_at][:hour].to_i,
      params[:batch_invoice_date_at][:minute].to_i,
      params[:batch_invoice_date_at][:second].to_i
    ) if params[:batch_invoice_date_at]

    # I didn't really feel the need to create a partial just for this one line:
    render :inline => '<%= batch_create_clients_form_column(@invoice_date_at) %>' if @invoice_date_at
  end

  def batch_create
    if params.has_key? :batch_client
     render(:update){|page| page << "alert('yoyoyoy');"} 
    else
      @invoice_date_at = Time.utc(*Time.now.to_a).prev_month.end_of_month
      render :action => :batch_create, :layout => false
    end
  end

  handle_extensions
  
  invoices_scaffold_init
end
