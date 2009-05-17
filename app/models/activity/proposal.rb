class Activity::Proposal < ActiveRecord::Base
  include ExtensibleObjectHelper
  include ActivityTypeModelHelper
  
  validates_presence_of :label
  validates_presence_of :proposed_on

  def name
    type_quick_namer '%s for %s on %s', label, client
  end
  
  handle_extensions
end

Activity.class_eval do
  has_one :proposal, :class_name => 'Activity::Proposal', :dependent => :destroy, :foreign_key => :activity_id
end