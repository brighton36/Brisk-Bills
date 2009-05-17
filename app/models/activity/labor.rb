class Activity::Labor < ActiveRecord::Base
  include ExtensibleObjectHelper
  
  def initialize(*args)
    # NOTE: This must be declared before the ActivityTypeModelHelper
    super(*args)
    self.minute_duration = 0 if minute_duration.nil?
  end
  
  include ActivityTypeModelHelper

  belongs_to :employee, :class_name => "::Employee"

  validates_presence_of :employee_id
  validates_numericality_of :minute_duration, :allow_nil => false
    
  validate :validate_duration

  def validate_duration
    errors.add :duration, 'invalid' if !@duration.nil? and self.minute_duration != @duration
  end
    
  def name
    type_quick_namer '%s at %s on %s', employee, client
  end

  def duration=(val)
    val = val.to_s unless val.class.name == 'String'

    self.minute_duration = @duration = case val
      # 40, 40m
      when /^[ ]*([\d]+)[ ]*[m]?[ ]*$/ then $1.to_i
      # 1h, 1hr
      when /^[ ]*([\d]+)[ ]*(h|hr)[ ]*$/ then $1.to_i*60
      # 1h 40m, 1 40, 1:15
      when /^[ ]*([\d]+)[ ]*(?:hr|[h\:]?)[ ]*([\d]{1,2})[ ]*[m]?[ ]*$/ then $1.to_i*60+$2.to_i
      # empty string?
      when /^[ ]*$/ then 0

      else raise StandardError
    end
  
    rescue 
      @duration = val
  end

  def friendly_duration
    hour = (self.minute_duration / 60).floor
    min  = (self.minute_duration % 60).round
   
    (hour > 0) ? sprintf( "%dhr %dmin", hour, min ) : "#{min}min"
    rescue
      ""
  end
  
  def clock_duration
    "%02d:%02d" % [ (minute_duration/60).floor, (minute_duration % 60).round ] unless minute_duration.nil?
  end
  
  alias duration clock_duration
  
  def as_legacy_ledger_row

    begin
      hourly_rate = '%.2f' % employee.labor_rate_for(activity.client).hourly_rate.to_f
    rescue
      hourly_rate = ' '
    end
    
    begin
      item_name = 'Labor-'+employee.short_name
    rescue
      item_name = 'Labor'
    end
    
    [
    '%.2fhr' % (minute_duration.to_f/60),
    hourly_rate,
    '%.2f' % activity.cost.to_f,
    item_name,
    occurred_on.strftime('%m/%d/%y'),
    comments.tr("\r\n", '')
    ]
  end

  handle_extensions
end

Activity.class_eval do
  has_one :labor, :class_name => 'Activity::Labor', :dependent => :destroy, :foreign_key => :activity_id
end