class Admin::DraftInvoicesController < Admin::InvoicesController
  
  @invoices_scaffold_config = superclass.instance_variable_get('@invoices_scaffold_config').dup

  invoices_scaffold_config do |config|
    config.label = "Draft Invoices"
    
    config.list.columns.instance_eval do 
      @set.delete(:is_published)
      @set.delete(:is_paid?)
    end
  end
  
  def conditions_for_collection
    ['is_published = ?', false]
  end 
    
  # TODO: Put in a plugin-helper
  # We need to be sure the view is looking in the right place, this little hack should do it:
  def self.active_scaffold_paths
    ret = super
    ret <<  BRISKBILLS_ROOT+'/app/views/admin/invoices'
    ret
  end
  # /TODO: Put in a plugin-helper
    
  handle_extensions
  
  invoices_scaffold_init
end
