class IsActiveEmployeesClients < ActiveRecord::Migration
  def self.up
    [:clients, :employees].each do |table_name| 
      add_column table_name, :is_active, :boolean, :default => true, :null => false
    end
  end
  
  def self.down
    [:clients, :employees].each { |table_name| remove_column table_name, :is_active }
  end
end