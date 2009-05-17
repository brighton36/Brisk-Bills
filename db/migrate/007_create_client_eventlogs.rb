class CreateClientEventlogs < ActiveRecord::Migration
  def self.up
    create_table :client_eventlogs do |t|
      t.integer   :client_id
      t.text      :description
      t.timestamp :created_at
    end
  end

  def self.down
    drop_table :client_eventlogs
  end
end
