class Notifier < ActionMailer::Base

  def reset_password_requested( credential_name, credential_email, reset_token, host )
    tmpl_parameters = {
      :reset_token      => reset_token,
      :credential_name  => credential_name,
      :credential_email => credential_email,
      :reset_password_url_for => {
        :controller    => 'authentication', 
        :action        => 'reset_password_via_token', 
        :email_address => credential_email,
        :token         => reset_token,
        :only_path     => false,
        :host          => host
      }
    }.merge common_tmpl_parameters

    from       from_address(tmpl_parameters)
    bcc        from_address(tmpl_parameters)
    recipients '%s <%s>' % [credential_name, credential_email] 
    subject    "%s - Password Reset Instructions" % tmpl_parameters[:company_name]
    
    generate_view_parts :reset_password_requested, tmpl_parameters
  end

  def invoice_available( invoice, client, payment_notice, attachments )
    tmpl_parameters = {
      :client => client,
      :payment_notice => payment_notice
    }.merge common_tmpl_parameters
    
    notifiers_bcc  = Setting.grab(:bcc_invoices_to)[0].split ','

    representative_emails = client.client_representatives.collect{|cr| '%s <%s>' % [cr.name,cr.email_address]}
    is_production = (RAILS_ENV == 'production')
    
    subject_line = "%s invoice %d (%s) now available"
    subject_line += " | Intended Recipients: "+representative_emails.join(', ') unless is_production

    # Here's the real deal
    from       from_address(tmpl_parameters)
    bcc        notifiers_bcc if is_production
    recipients (is_production) ? representative_emails : from_address(tmpl_parameters)
    subject    subject_line % [
      tmpl_parameters[:company_name],
      invoice.id,
      invoice.issued_on.strftime('%m/%d/%Y'),
      representative_emails.join(', ')
    ]

    generate_view_parts :invoice_available, tmpl_parameters

    attachments.each { |attach_params| attachment attach_params }
  end

  private

  def common_tmpl_parameters
    tmpl = {}
    setting_keys = %w(
      site_admin_name site_admin_email company_logo_file company_name company_address1 company_address2
      company_city company_state company_zip company_phone company_fax company_url
    ).collect{|s| s.to_sym}

    setting_vals = Setting.grab(*setting_keys)

    0.upto(setting_keys.length-1){ |i| tmpl[setting_keys[i]] = setting_vals[i] }

    tmpl
  end

  def from_address(tmpl)
    '%s <%s>' % [ tmpl[:site_admin_name], tmpl[:site_admin_email] ]
  end

  def generate_view_parts(view_name, tmpl)
    part( :content_type => "multipart/alternative" ) do |p|
      [
        { :content_type => "text/plain", :body => render_message("#{view_name.to_s}.plain.erb", tmpl) },
        { :content_type => "text/html",  :body => render_message("#{view_name.to_s}.html.erb",  tmpl.merge({:part_container => p})) }
      ].each { |parms| p.part parms.merge( { :charset => "UTF-8", :transfer_encoding => "7bit"} ) }
    end
  end

end
