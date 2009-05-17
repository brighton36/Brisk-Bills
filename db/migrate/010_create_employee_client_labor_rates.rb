class CreateEmployeeClientLaborRates < ActiveRecord::Migration
  def self.up
    create_table :employee_client_labor_rates, :options => 'TYPE=InnoDB' do |t|
      # Note : The only reason we really have an id here is b/c it makes things easier with ActiveScaffold
      t.integer   :employee_id
      t.integer   :client_id
      
      t.column :hourly_rate, :decimal, :default => nil, :null => true, :precision => 10, :scale => 2
      t.timestamps
    end
    
    add_index :employee_client_labor_rates, [:employee_id]
    add_index :employee_client_labor_rates, [:client_id]
  end

  def self.down
    drop_table :employee_client_labor_rates
  end
end
