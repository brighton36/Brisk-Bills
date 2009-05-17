module Admin::LaborsHelper
  include ExtensibleObjectHelper
  include Admin::ActivityTypeFieldHelper
  
  def duration_column(record)
    h record.friendly_duration
  end

  def to_money(val)
    raise StandardError if nil
    raise StandardError if val.class.to_s == 'String' and !/^[\-]?(?:[\d]+|[\d]+\.[\d]+|\.[\d]+)$/.match(val)
    
    "%.2f" % val.to_f
    
    rescue
      nil
  end

  handle_extensions
end
