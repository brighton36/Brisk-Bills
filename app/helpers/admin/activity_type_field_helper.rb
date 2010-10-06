module Admin::ActivityTypeFieldHelper
  
  include Admin::IsActiveColumnHelper

  def client_form_column(record, input_name) 
    select_tag(
      input_name, 
      options_for_select(
        (Client.find(
          :all, 
          :select => 'id, company_name', 
          :order => 'company_name ASC'
        ).collect {|c| [ c.company_name, c.id ] })+[['(Select Client)',nil]],
        record.activity.client_id
      ),
      options_for_column('client')
    )
  end
  
  def occurred_on_form_column(record, input_name)
    datetime_select "record", "occurred_on"
  end
  
  def cost_column(record)
    h_money (record.cost) ? record.cost : Money.new(0)
  end
  
  def tax_column(record)
    h_money (record.tax) ? record.tax : Money.new(0)
  end

  def cost_form_column(record,input_name)
    text_field_tag input_name, (@record.cost.nil?) ? nil : ("%.2f" % @record.cost), :size => 10, :id => "record_cost_#{record.id}"
  end
  
  def tax_form_column(record,input_name)
    text_field_tag input_name, (@record.tax.nil?) ? nil : ("%.2f" % @record.tax), :size => 10, :id => "record_tax_#{record.id}"
  end
  
  # Not all the activities have this, but many do:
  def comments_form_column(record,input_name)
    text_area_tag input_name, record.comments, :cols => 80, :rows => 22, :id => "record_comments_#{record.id}"
  end

end