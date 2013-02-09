class CreateInvoices < ActiveRecord::Migration
  def self.up
    create_table :invoices do |t|
      t.integer   :client_id
      t.text      :comments
      t.timestamp :issued_on
      t.boolean   :is_published, :default => 0, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :invoices
  end
end
