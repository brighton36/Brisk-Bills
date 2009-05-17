class CreateSlimtimerTasks < ActiveRecord::Migration
  def self.up
    create_table :slimtimer_tasks, :options => 'TYPE=InnoDB' do |t|
      # Owner id:
      t.column :owner_employee_slimtimer_id, :integer
      
      t.column :name,         :string
      
      t.column :default_client_id, :integer
      
      t.column :st_created_at,    :timestamp
      t.column :st_updated_at,   :timestamp
      
      t.timestamps
    end
  end

  def self.down
    drop_table :slimtimer_tasks
  end
end
