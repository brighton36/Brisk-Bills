class Admin::InvoicesController < ApplicationController
  include AdminLayoutHelper
  include ExtensibleObjectHelper

  include ::InvoicePdfHelper
  
  add_layout_conditions :except => 'download'

  active_scaffold :invoices_with_total do |config|
    config.label = "Invoices"

    config.show.columns = config.columns = [
      :id,
      :issued_on,
      :client,
      :sub_total,
      :taxes_total,
      :amount,
      :comments, 
      :is_published,
      :is_paid?,
      :paid_on, 
      :amount_paid,
      :amount_outstanding,
      :created_at, 
      :updated_at
    ]

    config.columns[:is_paid?].sort_by :sql => '`invoices_with_totals`.is_paid'

    config.columns[:id].label = 'Num'
    config.columns[:is_published].label = 'Pub?'
    config.columns[:is_paid?].label = 'Paid?'
    config.columns[:activity_types].label = 'Include Activities'
    config.columns[:amount].label = 'Total'
    config.columns[:issued_on].label = 'Issued'
    
    config.columns[:amount].sort_by :sql => 'amount_in_cents'
    
    config.columns[:client].sort_by :sql => "clients.company_name"
    config.columns[:client].form_ui = :select
    
    config.columns[:activity_types].form_ui = :select
        
    config.list.columns =[:id, :issued_on, :client,  :amount, :is_published, :is_paid?]
    config.list.sorting = [{:issued_on => :desc}]
    
    config.create.columns = config.update.columns = [:issued_on, :is_published, :client, :activity_types, :comments]

    config.action_links.add ActiveScaffold::DataStructures::ActionLink.new(
      'download', 
      :label  => 'Download', 
      :type   => :record,
      :inline => false,
      :page   => true
    )

    config.nested.add_link "Activities", [:activities]
    
    config.full_list_refresh_on = [:update, :create]

  end
  
  def self.active_scaffold_controller_for(klass)
    (klass == Activity) ? Admin::ActivitiesWithPricesController : super
  end

  def after_update_save(invoice)
    super
    
    if successful? and invoice.is_published # TODO: And only if is_published has changed?...
      define_invoice invoice
      
      attachments = [
        {
        :content_type => "application/pdf", 
        :body         => render_to_string(:action => 'download', :layout => false),
        :disposition  => "attachment",
        :filename     => @rails_pdf_name
        }
      ]
      
      mail = Notifier.deliver_invoice_available @invoice, @client, @footer_text, attachments
      
      dest_addresses = []
      dest_addresses += mail.to_addrs if mail.to_addrs
      dest_addresses += mail.cc_addrs if mail.cc_addrs
      
      dest_addresses.collect!{|t_a| '%s <%s>' % [t_a.name, t_a.address] }
      
      flash[:warning]  = "Invoice e-mailed to : %s" % dest_addresses.join(',')
    end
  end
    
  alias after_create_save after_update_save

  def download
    define_invoice Invoice.find(params[:id].to_i, :include => [:client])
    
    rescue 
      render :file => RAILS_ROOT+'/public/500.html', :status => 500
  end

  private
  
  BAD_INDIFFERENTIZE_VARS =  /^\@(#{%w(
    request_origin _request active_scaffold_observations variables_added before_filter_chain_aborted
    rendering_runtime query action_name _flash performed_render url _headers _cookies db_rt_after_render
    assigns template _params performed_redirect successful db_rt_before_render _session _response
  ).join('|')})$/

  def indifferentize_instance_vars
    # We use this to pass the controller vars over to the mailer. This mostly removes the preceeding @'s
    ret = HashWithIndifferentAccess.new
    
    instance_variables.each do |v| 
      ret[/^[\@](.+)/.match(v).to_a[1]] = instance_variable_get v unless BAD_INDIFFERENTIZE_VARS.match v
    end
  
    ret
  end
  
  def define_invoice(invoice)    
    ( @company_name,
      @company_url,
      @company_address1,
      @company_address2,
      @company_city,
      @company_state,
      @company_zip,
      @company_phone,
      @company_fax,
      company_logo_file ) = 
    Setting.grab( 
      :company_name, 
      :company_url, 
      :company_address1, 
      :company_address2, 
      :company_city, 
      :company_state, 
      :company_zip, 
      :company_phone, 
      :company_fax,
      :company_logo_file
    )
    
    @company_logo_path = '%s/public/images/%s' % [BRISKBILLS_ROOT, company_logo_file]
    
    @footer_text = "Thank-you for choosing %s! All payments are due within thirty days of receipt. We take checks, cash, and major credit cards. We appreciate your business, and encourage you to call us at %s if there are any discrepencies or concerns." % [@company_name, @company_phone]

    @invoice = invoice
    
    raise StandardError if @invoice.nil? or @invoice.client.nil?
    
    @client = @invoice.client
    @invoice_number = @invoice.id
    @issued_on = @invoice.issued_on
    
    @rails_pdf_name = 'Invoice - %s (%s).pdf' % [@client.name.tr('^a-zA-Z -',''), @invoice_number]
    
    @invoice_rows = @invoice.activities.find(:all, :order => 'occurred_on ASC').collect { |a| a.sub_activity.as_legacy_ledger_row }
  end

  handle_extensions
end
