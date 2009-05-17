class CreateStSettings < ActiveRecord::Migration
  def self.up
    Setting.create(
    :keyname     => :slimtimer_sync_start_days_ago.to_s,
    :label       => 'SlimTimer Sync Tasks Starting From',
    :description => 'How many days ago, to use as a starting point for slimtimer synchrnization',
    :keyval      => 0.to_s
    )
  end

  def self.down
    Setting.find(
      :first, 
      :conditions => ['keyname = ?', 'slimtimer_sync_start_days_ago']
    ).destroy
  end
end
