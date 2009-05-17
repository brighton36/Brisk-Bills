class CreateClients < ActiveRecord::Migration
  def self.up
    create_table :clients, :options => 'TYPE=InnoDB' do |t|
      t.string  :company_name, :address1, :address2, :city, :state, :zip, :phone_number, :fax_number
      t.timestamps
    end
  end

  def self.down
    drop_table :clients
  end
end
