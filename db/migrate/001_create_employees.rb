class CreateEmployees < ActiveRecord::Migration
  def self.up
    create_table :employees, :options => 'TYPE=InnoDB' do |t|
       t.string  :first_name, :last_name, :email_address, :password
       t.integer :phone_extension

       t.timestamps
    end
  end

  def self.down
    drop_table :employees
  end
end
