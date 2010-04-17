module Admin::PaymentsHelper
  include Admin::IsActiveColumnHelper
  
  def amount_column(record)
    h_money record.amount
  end

  def payment_method_identifier_form_column(record, input_name)
    text_field_tag(
      input_name, 
      record.payment_method_identifier, 
      options_for_column('payment_method_identifier').merge({:size => 30})
    )
  end

  def unallocated_amount_form_column(record, input_name)
    '<span class="active-scaffold_detail_value" id="record_unallocated_amount_%s">%s</span>' % [record.id, '(Enter a Payment Amount)']
  end
  
  def invoice_assignment_form_column(record, input_name)
#    list_i = nil
#    
#    Client.find(:all, :order => 'company_name ASC').in_groups_of((Client.count(:all).to_f/3).ceil, false).collect{ |group|
#      '<ul class="checkbox-list">'+
#        group.collect{ |client|
#          list_i = (list_i) ? list_i+1 : 0
#          chk_name = "%s[%d][id]" % [input_name, client.id]
#          
#          '<li>%s<label for="%s[%d][id]">%s</label></li>' % [ 
#            check_box_tag(chk_name, client.id, record.client_ids.include?(client.id) ), 
#            chk_name,
#            list_i,
#            client.company_name
#          ]
#        }.join+
#      '</ul>'
#    }.join
    '<div id="record_invoice_assignment_%s">%s</div>' % [record.id, '<span class="active-scaffold_detail_value">(Choose a Client)</span>']
  end

end
