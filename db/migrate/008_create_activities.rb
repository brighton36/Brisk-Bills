class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table :activities, :options => 'TYPE=InnoDB' do |t|
      t.integer   :client_id, :invoice_id
      t.boolean   :is_published, :default => 0, :null => false
      t.string    :activity_type
      t.timestamp :occurred_on
      t.decimal   :cost, :precision => 10, :scale => 2
      
      t.timestamps
    end
  end

  def self.down
    drop_table :activities
  end
end
