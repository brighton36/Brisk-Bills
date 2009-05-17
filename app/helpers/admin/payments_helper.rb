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

end
