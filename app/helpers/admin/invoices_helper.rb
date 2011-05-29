module Admin::InvoicesHelper
  
  def active_scaffold_input_options(column, scope = nil, options = {})
    options = super(column, scope, options)
    options.merge! :include_seconds => true if column.name == :issued_on        
    options
  end
  
  def invoices_with_total_is_published_form_column(column, options)
    select_tag options[:name], options_for_select([['Yes', 1],['No',0]], (column.is_published) ? 1 : 0 ) 
  end

  def invoices_with_total_is_published_column(record)
    record.is_published ? 'Yes' : 'No'
  end
  
  def invoices_with_total_is_paid_column(record)
    record.is_paid? ? 'Yes' : 'No'
  end

  def invoices_with_total_sub_total_column(record)
    h_money record.sub_total
  end

  def invoices_with_total_taxes_total_column(record)
    h_money record.taxes_total
  end

  def invoices_with_total_amount_column(record)
    h_money record.amount
  end
  
  def invoices_with_total_issued_on_column(record)
    h record.issued_on.strftime((params[:action] == 'show') ? '%m/%d/%y %I:%M %p' : '%m/%d/%y')
  end
  
  def invoices_with_total_payment_assignments_column(record)
    record.payment_assignments.collect{ |asgn|
      '%s from (Payment %d)' % [asgn.amount.format, asgn.payment_id  ]
    }.join ', '
  end

  # Shameless copy-paste:
  def invoices_with_total_activity_types_form_column(column, options)
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
