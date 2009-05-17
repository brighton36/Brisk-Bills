module Admin::ActivityTaxFieldHelper
  
  def tax_column(record)
    h_money (record.tax) ? record.tax : 0.0
  end  
  
  def apply_tax_form_column(record, input_name)
    check_box_tag input_name, 'yes', (@record.tax) ? true : false, options_for_column('apply_tax')
  end

  def tax_form_column(record, input_name)   
    html_options = options_for_column('tax').merge({:size => 10 })

    as_columns = @controller.active_scaffold_config.columns

    is_disabled = @record.tax.nil? and as_columns[:apply_tax]
    
    # I don't really like this, but for now I guess, I'll take it ...
    is_disabled = false if (
      @record.respond_to?(:activity_type) and 
      as_columns[:apply_tax].respond_to?(:for_activity_type?) and 
      !as_columns[:apply_tax].for_activity_type?(@record.activity_type)
    )

    html_options.merge!( 
      { :disabled => true, :class => 'disabled' } 
    ) if is_disabled
    
    # We put this hidden field here, b/c apparently when a field is html-disabled, it doesn't submit. And this causes problems with the apply_tax js
    hidden_field_tag(input_name, '', {:disabled => !is_disabled, :id => ('%s_hidden' % html_options[:id])})+
    text_field_tag(input_name, money_for_input(@record.tax), html_options)
  end
end