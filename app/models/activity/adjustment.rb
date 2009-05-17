class Activity::Adjustment < ActiveRecord::Base
  include ExtensibleObjectHelper
  include ActivityTypeModelHelper
  
  validates_presence_of :label
  
  def name
    type_quick_namer '%s for %s on %s', label, client
  end

  def as_legacy_ledger_row
    
    if label and comments and label.length > 0 and comments.length > 0
      description = '%s - %s' % [label, comments]
    else
      description = (comments and comments.length > 0) ? comments : label
    end
    
    [
    1,
    activity.cost,
    activity.cost,
    'Adjustment',
    occurred_on.strftime('%m/%d/%y'),
    description.tr("\r\n", '')
    ]
  end

  handle_extensions
end

Activity.class_eval do
  has_one :adjustment, :class_name => 'Activity::Adjustment', :dependent => :destroy, :foreign_key => :activity_id
end