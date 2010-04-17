# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def h_money(amount, inverse_polarity = false)    
    '<span class="%s">$%s</span>' % [ 
      ( (inverse_polarity ? (amount > 0 ) : (amount < 0 )) ? 'money_negative':'money_positive' ), 
      amount.to_s.gsub(/(\d)(?=\d{3}+(\.\d*)?$)/, '\1,')
    ] unless amount.nil?
  end
  
  def money_for_input(cost)
    '%.2f' % cost
  end
  
  def define_application_layout_variables
    company_name = Setting.grab :company_name
    
    @site_title = company_name if @site_title.nil?
    @page_title = "#{params[:controller]}::#{params[:action]}" if @page_title.nil?
    
    @body_id = request.request_uri.sub(/^#{root_url(:only_path => true)}/, '').sub(/\?.+$/,'').tr(' ','-').gsub(/[^a-z\/0-9\-_]/,'').tr('/','_').gsub(/[\-]{2,}/,'-')
    @body_class = /(.*?)_[^_]+$/.match(@body_id).to_a.pop
    
    @javascripts = ['scriptaculous.js?load=effects', 'modalbox.js','briskbills-quick-helpers.js']
    @stylesheets = ['modalbox.css']
  end
end
