
# For now, its just this very simple fix...
module ActiveScaffoldAsGemFeatures

  def self.included(base)
    base.module_eval do
      alias :active_scaffold_without_gem :active_scaffold
      alias :active_scaffold :active_scaffold_as_gem
    end
  end
  
  def active_scaffold_as_gem(model_id = nil, &block)
    active_scaffold_without_gem(model_id, &block)

    # We need to be sure to search the BRISKBILLS_ROOT after RAILS_ROOT
    @active_scaffold_frontends << "#{BRISKBILLS_ROOT}/vendor/plugins/active_scaffold/frontends/default/views"
  end
  
end

ActiveScaffold::ClassMethods.send :include, ActiveScaffoldAsGemFeatures unless BriskBills.loaded_via_app?