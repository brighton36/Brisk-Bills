class Employee < ActiveRecord::Base
  include ExtensibleObjectHelper
  include IsActiveModelHelper
  include HasCredentialModelHelper

  has_many :employee_client_labor_rates, :class_name => 'EmployeeClientLaborRate'

  before_destroy :ensure_not_referenced_on_destroy

  validates_presence_of [:first_name,:last_name, :email_address]
  
  validates_format_of [:first_name,:last_name], :with => /\A[a-z0-9 \-]+\Z/i
  validates_format_of :email_address, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  
  validates_numericality_of :phone_extension, :allow_nil => true

  def name
    ret = String.new
    
    ret += first_name if !first_name.nil? and first_name.length > 0
    
    ret += (ret.length > 0) ? " #{last_name}" : last_name if !last_name.nil? and last_name.length > 0
    
    ret
  end

  def short_name
    if first_name.length > 0 and last_name.length > 0
      (first_name[0...1] + last_name).downcase
    else
      (first_name.length > 0) ? first_name.downcase : last_name.downcase
    end
  end
  
  def ensure_not_referenced_on_destroy
    ( errors.add_to_base "Can't destroy a referenced employee" and return false ) unless authorized_for? :action => :destroy
  end

  def authorized_for?(options)
    case options[:action]
      when :destroy
        ( Activity::Labor.count( :all, :conditions => ['employee_id = ?', id] ) > 0 ) ? false : true
      else
        true
    end
  end
  
  handle_extensions
end
