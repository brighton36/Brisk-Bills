class Setting < ActiveRecord::Base
  validates_presence_of :keyname
  validates_presence_of :label
  
  validates_uniqueness_of :keyname
  validates_uniqueness_of :label
  
  def self.grab(*args)
    map = HashWithIndifferentAccess.new

    Setting.find(
      :all, 
      :select => '`keyname`, `keyval`', 
      :conditions => ['keyname IN (?)', args.collect(&:to_s)]
    ).each { |s| map[s.keyname] = s.keyval }

    args.collect {|a| (map.key? a) ? map[a] : nil }
  end
  
  def self.exists?(keyname)
    (Setting.find( :first, :select => '`id`', :conditions => [ 'keyname = ?', keyname.to_s] )) ? true : false
  end
  
  def self.set!(keyname,value)
    setting = Setting.find(:first, :conditions => [ 'keyname = ?', keyname.to_s ] )
    
    raise StandardError unless setting
    
    setting.keyval = value.to_s
    setting.save!
    
    setting.keyval
  end
  
  def authorized_for?(options)
    (options[:action] == :destroy) ? false : true
  end
  
end
