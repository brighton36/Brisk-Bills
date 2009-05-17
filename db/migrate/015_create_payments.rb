class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments, :options => 'TYPE=InnoDB' do |t|
      t.integer   :client_id
      t.integer   :payment_method_id
      t.text      :payment_method_identifier  # Check No./Card Name/last four
      t.decimal   :amount, :precision => 10, :scale => 2
      t.timestamp :paid_on

      t.timestamps
    end

  end

  def self.down
    drop_table :payments
  end
end
