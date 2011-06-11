require 'ostruct'

require "#{BRISKBILLS_ROOT}/lib/dti-navigation-menu/lib/dti-navigation-menu"

class ResourceNotFound < StandardError    
end

class NavigationLink < OpenStruct
  def link_depth
    # This really isn't the best way to do this, but, it works for this site
    
    self.url.count '/'
  end
  
  def link_id
    self.title.downcase.gsub(/[^a-z0-9 ]/i,'').tr(' ','_').gsub(/[\_]{2,}/,'_')
  end
end

module AdminLayoutActiveScaffoldHelper
  def list_with_admin_layout_helper
    @page_title = active_scaffold_config.label
    
    define_layout_variables
    list_without_admin_helper
  end
  
  def self.append_features(base)
    super
    base.class_eval do 
      unless self.method_defined? :list_without_admin_helper
        alias :list_without_admin_helper :list 
        alias :list :list_with_admin_layout_helper
      end
    end
  end

end

ActiveScaffold::Actions::List.send :include, AdminLayoutActiveScaffoldHelper

module AdminLayoutHelper
  include ApplicationHelper  

  def define_layout_variables
    define_application_layout_variables

    @main_navigation = NavigationMenu.new('Administration') do |admin|
      admin.item('Activity Management', controller_url("Admin/Activities")) do |activity|
        activity.item 'Labor',          controller_url("Admin/Labors")
        activity.item 'Materials',      controller_url("Admin/Materials") 
        activity.item 'Proposals',      controller_url("Admin/Proposals")
        activity.item 'Adjustments',    controller_url("Admin/Adjustments")
      end

      admin.item 'Accounts Ledger', controller_url("Admin/Client_Accounting") do |accounting|
        accounting.item 'All Invoices', controller_url("Admin/Invoices")
        accounting.item 'Draft Invoices', controller_url("Admin/draft_invoices")
        accounting.item 'Payments', controller_url("Admin/Payments")
      end

      admin.item( 'Clients',            controller_url("Admin/Clients") ) do |clients|
        clients.item 'Representatives', controller_url("Admin/Client_Representatives")
      end
      
      admin.item 'Employees', controller_url("Admin/Employees")
      
      admin.item 'Site Settings',  controller_url("Admin/Settings")

      admin.item 'Sign-Out',  logout_url, ['distance']
    end
  end
  
  def controller_url( for_controller )
    url_for :controller => for_controller, :only_path => true
  end

  def self.append_features(base)
    super
    
    base.class_eval do
      layout 'admin'
      
      
    end
  end

end
