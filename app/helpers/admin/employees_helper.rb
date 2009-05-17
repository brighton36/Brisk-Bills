module Admin::EmployeesHelper
  
  include ExtensibleObjectHelper
  
  include Admin::IsActiveColumnHelper
  include Admin::HasCredentialColumnHelper

  handle_extensions
end
