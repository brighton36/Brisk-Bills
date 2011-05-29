module Admin::ActivitiesHelper
  include ::Admin::ActivityTaxFieldHelper
  include ExtensibleObjectHelper

  def active_scaffold_observe_field(col_name, observation)
    # This is slightly hackish - but it should work
    # We Make sure we're supposed to be rendering here based on the :for_activities option

    (observation[:for_activities].include? @record.activity_type) ? super(col_name, observation) : String.new
  end

  def override_form_field(*args)
    ret = super(*args)

    ret
  end

  # List Helpers:
  def render_list_column(text, column, record)
    return super unless column.name == :activity
    
    activity_partial = "#{record.activity_type}_column"
    
    if FileTest.exists? "#{activity_partial_path}/_#{activity_partial}.html.erb"
      render :partial => activity_partial, :locals => { :record => record }
    else
      '-'
    end
  end
  
  def get_column_value(record, column)
    return super unless column.name == :activity
    
    nil
  end
  
  def column_class(column, column_value)
     return super unless column.name == :activity
      
    "#{column.name}-column"
  end

  def cost_column(record)
    h_money record.cost
  end

  def tax_column(record)
    h_money record.tax
  end
    
  # Form Helper Routing:
  def active_scaffold_input_for(column, scope = nil)
    super column, scope unless column.name == :activity
  end
  
  def override_form_field(column)
    subtype_override_method = "activity_#{@record.activity_type}_#{column.name}_form_column"
    
    respond_to?(subtype_override_method) ? subtype_override_method : "activity_#{column.name}_form_column"
  end

  # Generic helpers:
  
  def activity_cost_form_column(record, input_name)
    text_field_tag input_name, money_for_input(@record.cost), options_for_column('cost').merge({:size => 10 })
  end
  
  def activity_client_id_form_column(record, input_name)
    select_tag(
      input_name, 
      options_for_select(
        # NOTE: We don't do a find_active here, but see the conditions...
        [ ['(Unknown)', nil] ]+Client.find(
         :all, 
         :select => 'id, company_name', 
         :order => 'company_name ASC',
         :conditions => ['is_active = ? OR id = ?', true, @record.client_id]
        ).collect {|c| [ c.company_name, c.id ] },
        @record.client_id
      ),
      options_for_column('client_id')
    )
  end
  
  def activity_label_form_column(record, input_name)
    label_value = (@record.respond_to?(@record.activity_type)) ? @record.send("#{@record.activity_type}").label : nil
    
    text_field_tag input_name, label_value, options_for_column('label').merge({:size => 30 })
  end
  
  def activity_comments_form_column(record, input_name)
    comments_value = (@record.respond_to?(@record.activity_type)) ? @record.send("#{@record.activity_type}").comments : nil
    
    text_area_tag input_name, comments_value, options_for_column('comments').merge({:cols => 72, :rows => 20})
  end
  
  def submit_tag(*args)
    args[0] = 'Approve' if args[0] == 'Update' and (!params.has_key?(:nested) or params[:nested] == false)
    super(*args)
  end


  private
  
  def activity_partial_path
    "#{BRISKBILLS_ROOT}/app/views/admin/activities"
  end
  
  handle_extensions
end
