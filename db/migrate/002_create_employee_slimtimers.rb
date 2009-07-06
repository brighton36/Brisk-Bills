class CreateEmployeeSlimtimers < ActiveRecord::Migration
  def self.up
    create_table :employee_slimtimers, :options => 'TYPE=InnoDB' do |t|
       t.column :employee_id,   :integer, :null => false
       t.column :api_key,       :string
       t.column :username,      :string
       t.column :password,      :string
    end
  end

  def self.down
    drop_table :employee_slimtimers
  end
end
