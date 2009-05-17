module Admin::InvoicesHelper
  
  include Admin::IsActiveColumnHelper
  
  def is_published_form_column(column, input_name)
    select_tag input_name, options_for_select([['Yes', 1],['No',0]], (column.is_published) ? 1 : 0 ) 
  end

  def is_published_column(record)
    record.is_published ? 'Yes' : 'No'
  end
  
  def is_paid_column(record)
    record.is_paid? ? 'Yes' : 'No'
  end

  def sub_total_column(record)
    h_money record.sub_total
  end

  def taxes_total_column(record)
    h_money record.taxes_total
  end

  def amount_column(record)
    h_money record.amount
  end
  
  def issued_on_column(record)
    h record.issued_on.strftime((params[:action] == 'show') ? '%m/%d/%y %I:%M %p' : '%m/%d/%y')
  end

  # Shameless copy-paste:
  def activity_types_form_column(column, input_name)
    available_types = ActivityType.find(:all)
    
    associated_ids = ( (@record.new_record?) ? available_types : @record.activity_types ).collect(&:id)

    return 'no options' if available_types.empty?

    html = '<ul class="checkbox-list">'
    available_types.each_with_index do |type, i|
      this_name = "#{input_name}[#{i}][id]"
      html << "<li>"
      html << check_box_tag(this_name, type.id, associated_ids.include?(type.id))
      html << "<label for='#{this_name}'>"+type.to_label+"</label>"
      html << "</li>"
    end
    html << '</ul>'
    html
  end

end
