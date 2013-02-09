class CreateClientRepresentatives < ActiveRecord::Migration
  def self.up
    create_table :client_representatives do |t|
      t.integer  :client_id
      t.string   :first_name, :last_name, :title, :cell_phone, :email_address, :password
#      t.boolean  :accepts_tos, :default => 0, :null => false
      t.integer  :accepts_tos_version, :default => 0
      t.text     :notes
      t.timestamps
    end
  end

  def self.down
    drop_table :client_representatives
  end
end
