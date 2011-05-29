module Admin::EmployeesHelper
  
  include ExtensibleObjectHelper
  
  include Admin::IsActiveColumnHelper
  
  alias :employee_is_active_form_column :is_active_form_column
   
  include Admin::HasCredentialColumnHelper
  
  alias :employee_password_form_column :password_form_column
  alias :employee_login_enabled_form_column :login_enabled_form_column

  handle_extensions
end
