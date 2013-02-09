class CreateActivityLabors < ActiveRecord::Migration
  def self.up
    create_table :activity_labors do |t|
      
      t.integer :employee_id, :activity_id
      t.text    :comments
      t.integer :minute_duration

      t.timestamps
    end
  end

  def self.down
    drop_table :activity_labors
  end
end
