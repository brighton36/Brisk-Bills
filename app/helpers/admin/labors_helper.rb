module Admin::LaborsHelper
  include ExtensibleObjectHelper
  include Admin::ActivityTypeFieldHelper
  
  alias :activity_labor_tax_column :tax_column
  alias :activity_labor_cost_column :cost_column
  
  alias :activity_labor_occurred_on_form_column :occurred_on_form_column
  alias :activity_labor_client_form_column :client_form_column
  alias :activity_labor_cost_form_column :cost_form_column
  
  alias :activity_labor_tax_form_column :tax_form_column
  alias :activity_labor_comments_form_column :comments_form_column 
  
  
  def activity_labor_duration_column(record)
    h record.friendly_duration
  end

  def to_money(val)
    raise StandardError if nil
    raise StandardError if val.class.to_s == 'String' and !/^[\-]?(?:[\d]+|[\d]+\.[\d]+|\.[\d]+)$/.match(val)
    
    "%.2f" % val.to_f
    
    rescue
      nil
  end

  handle_extensions
end
