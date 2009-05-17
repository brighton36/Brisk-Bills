class Activity::Material < ActiveRecord::Base
  include ExtensibleObjectHelper
  include ActivityTypeModelHelper
  
  validates_presence_of :label

  def name
    type_quick_namer '%s for %s on %s', label, client
  end
  
  handle_extensions
end

Activity.class_eval do
  has_one :material, :class_name => 'Activity::Material', :dependent => :destroy, :foreign_key => :activity_id
end