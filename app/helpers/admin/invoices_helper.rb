module Admin::InvoicesHelper
  
  def active_scaffold_input_options(column, scope = nil, options = {})
    options = super(column, scope, options)
    options.merge! :include_seconds => true if column.name == :issued_on        
    options
  end
  
  def invoice_is_published_form_column(column, options)
    select_tag options[:name], options_for_select([['Yes', 1],['No',0]], (column.is_published) ? 1 : 0 ) 
  end

  def invoice_is_published_column(record)
    record.is_published ? 'Yes' : 'No'
  end
  
  def invoice_is_paid_column(record)
    record.is_published ? (record.is_paid? ? 'Yes' : 'No') : '-'
  end

  def invoice_sub_total_column(record)
    h_money record.sub_total
  end

  def invoice_taxes_total_column(record)
    h_money record.taxes_total
  end

  def invoice_amount_column(record)
    h_money record.amount
  end
  
  def invoice_issued_on_column(record)
    h record.issued_on.strftime((params[:action] == 'show') ? '%m/%d/%y %I:%M %p' : '%m/%d/%y')
  end
  
  def invoice_payment_assignments_column(record)
    record.payment_assignments.collect{ |asgn|
      '%s from (Payment %d)' % [asgn.amount.format, asgn.payment_id  ]
    }.join ', '
  end
 
  def toggle_published_indicator
    loading_indicator_tag :action => :toggle_published, :id => @record.id
  end
   
  def toggle_published_submit( label, is_focused, url_options = {} )
    loading_indicator_id = loading_indicator_id(:action => :toggle_published, :id => @record.id)

    button_to_remote( 
      label,
      { 
        :url => {
          :action        => :toggle_published, 
          :id            => @record.id, 
          :is_confirmed  => 1
        }.merge(url_options),
        :loaded  => [
          'Modalbox.hide()',
          "$(%s).style.visibility = 'visible'"  % loading_indicator_id.to_json
        ].join(';'),
        :before  => [
          "$(%s).style.visibility = 'visible'" % loading_indicator_id.to_json,
          "$$('#MB_content input[type=button]').each(function(i){i.disable();} )",
          "$('cancel_box').style.display = 'none'"
        ].join(";"),
      },
      (is_focused) ? {:class => "MB_focusable"} : {}
    ) 
  end

  # This let's us hook into the action_link names, so we can dynamically generate a label 
  # for the publish/unpublish row action
  def render_action_link(link, url_options, record = nil, html_options = {})
    # We don't want to modify the config itself, so we dup it before we start 
    # on changes
    our_options = url_options.dup 
    
    if link.action == 'toggle_published'
      our_options[:link] = (record.is_published) ? 'Un-Publish' : 'Publish'
      
      html_options[:onclick] = "Modalbox.show(%s,%s); return false;" % [
        url_for(:action => :toggle_published, :id => record.id).to_json,
        {
        :title => '%s confirmation' %  [(record.is_published) ? 'Un-publish' : 'Publish'], 
        :width => 700
        }.to_json
      ]
    end
    
    super(link, our_options, record, html_options)
  end

  # Shameless activescaffold copy-pasta:
  def invoice_activity_types_form_column(column, options)
    available_types = ActivityType.find(:all)
    
    associated_ids = ( (@record.new_record?) ? available_types : @record.activity_types ).collect(&:id)

    return 'no options' if available_types.empty?

    html = '<ul class="checkbox-list">'
    available_types.each_with_index do |type, i|
      this_name = "#{options[:name]}[#{i}][id]"
      html << "<li>"
      html << check_box_tag(this_name, type.id, associated_ids.include?(type.id))
      html << "<label for='#{this_name}'>"+type.to_label+"</label>"
      html << "</li>"
    end
    html << '</ul>'
    html
  end

end
