module Admin::ClientsHelper
  include ExtensibleObjectHelper
  include Admin::IsActiveColumnHelper
    
  alias :client_is_active_form_column :is_active_form_column
  
  handle_extensions
end
