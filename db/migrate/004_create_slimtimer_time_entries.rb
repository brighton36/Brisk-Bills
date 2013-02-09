class CreateSlimtimerTimeEntries < ActiveRecord::Migration
  def self.up
    create_table :slimtimer_time_entries do |t|
      
      t.column :employee_slimtimer_id, :integer
      t.column :slimtimer_task_id,     :integer
      t.column :activity_labor_id,     :integer
      
      t.column :comments,   :text
      t.column :tags,       :text

      t.column :start_time, :datetime
      t.column :end_time,   :datetime

      t.column :st_updated_at, :timestamp
      t.column :st_created_at, :timestamp
      
      t.timestamps
    end
  end

  def self.down
    drop_table :slimtimer_time_entries
  end
end
