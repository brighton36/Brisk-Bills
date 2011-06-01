module Admin::MaterialsHelper
  include ::Admin::ActivityTypeFieldHelper
  include ::Admin::ActivityTaxFieldHelper
  
  alias :activity_material_tax_column :tax_column
  alias :activity_material_cost_column :cost_column
  
  alias :activity_material_occurred_on_form_column :occurred_on_form_column
  alias :activity_material_client_form_column :client_form_column
  alias :activity_material_cost_form_column :cost_form_column
  
  alias :activity_material_tax_form_column :tax_form_column
  alias :activity_material_comments_form_column :comments_form_column 
  
  alias :activity_material_apply_tax_form_column :apply_tax_form_column
end
