class CreateInvoicePayments < ActiveRecord::Migration
  def self.up
    create_table( :invoice_payments) do |t|
      t.integer :payment_id, :invoice_id, :null => false
      t.decimal :amount, :precision => 10, :scale => 2,  :null => false
    end
    
    add_index :invoice_payments, [:payment_id, :invoice_id]
  end

  def self.down
    drop_table :invoice_payments
  end
end
