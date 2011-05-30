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
    
    config.show.columns = [
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
      :payment_assignments,
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
    
    config.create.columns = config.update.columns = [
      :issued_on, :is_published, :client, :activity_types, :comments
    ]

    config.create.link

    config.action_links.add(
      'download', 
      :label  => 'Download', 
      :type   => :member,
      :inline => false,
      :page   => true
    )

    config.nested.add_link "Activities", :activities     
    config.full_list_refresh_on = [:update, :create]

  end
  
  # override_form_field_partial in the helper gets buggered out b/c our controller name doesn't match
  # the model name. This fixes that:
  def self.active_scaffold_controller_for(klass)
    (klass == Activity) ? Admin::ActivitiesWithPricesController : self
  end

  # We ovverride the defaut behavior here only so that we can use this method as a hook to detyermine the invoice.activity_type_ids
  # Before they've been updated by the form. We reference @activity_type_ids_before in before_update_save to determine whether we
  # need to update the activity associations for this invoice.
  def update_record_from_params(*args)
    @activity_type_ids_before = @record.activity_type_ids.dup if @record
    super
  end

  def before_update_save(invoice)
    super
       
    invoice.activities = invoice.recommended_activities if (
      invoice.new_record? or (
        !invoice.is_published and
        # Unfortunately, there's no easy way to accomplish a invoice.activity_types.changed?, so - this will 
        # effectively ascertain that answer by comparing the params against the activity_type_ids 
        (invoice.issued_on_changed? || (@activity_type_ids_before != invoice.activity_type_ids))
      )
    )

    invoice.payment_assignments.clear if !invoice.is_published and invoice.is_published_changed?

    # We're going to need this in the after_update_save... Note it now.
    @invoice_changes = invoice.changes.keys.collect(&:to_sym)
    @invoice_new_record = invoice.new_record?
  end

  alias before_create_save before_update_save

  def after_update_save(invoice)
    super

    if successful? and invoice.is_published and (@invoice_new_record || @invoice_changes.include?(:is_published))
      # Unfortunately we have to assign payments using the quick_create and not by concat'ing on the
      # invoice AssociationProxy. THis is due to a bug in my InvoicesWithTotal wrapper that I think is related
      # to the association proxy not resettting its owenr id on an id change (as is the case of a create)
      invoice.client.recommend_payment_assignments_for(invoice.amount).each do |ip|
         InvoicePayment.quick_create! invoice.id, ip.payment_id, ip.amount
      end

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
