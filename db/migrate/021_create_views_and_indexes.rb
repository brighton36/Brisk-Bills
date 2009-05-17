class CreateViewsAndIndexes < ActiveRecord::Migration
  
  CREATE_INDEXES = { 
    :activities => [:invoice_id, :client_id], 
    :invoices   => [:client_id],
    :payments   => [:client_id, :payment_method_id]
  }

  CREATE_VIEWS = [
    ['clients_with_charges_sum', 
     'SELECT 
        invoices.client_id,
        SUM(activities.cost) AS charges_sum
      FROM invoices
      LEFT JOIN activities ON activities.invoice_id = invoices.id
      GROUP BY invoices.client_id;'],
    
    ['clients_with_payment_sum',
     'SELECT 
         payments.client_id, 
         SUM(payments.amount) AS payment_sum
       FROM payments
       GROUP BY payments.client_id;'],
    
    ['clients_with_balances',
     'SELECT
         clients.*,
         IF(SUM(activities.cost) IS NULL, 0, SUM(activities.cost)) AS uninvoiced_activities_balance,
         IF(clients_with_charges_sum.charges_sum IS NULL, 0,clients_with_charges_sum.charges_sum) AS charges_sum,
         IF(clients_with_payment_sum.payment_sum IS NULL, 0,clients_with_payment_sum.payment_sum) AS payment_sum,
         (
            IF(clients_with_charges_sum.charges_sum IS NULL, 0,clients_with_charges_sum.charges_sum)-
            IF(clients_with_payment_sum.payment_sum IS NULL, 0,clients_with_payment_sum.payment_sum)
         ) AS balance
       FROM clients
       LEFT JOIN clients_with_charges_sum ON clients_with_charges_sum.client_id = clients.id
       LEFT JOIN clients_with_payment_sum ON clients_with_payment_sum.client_id = clients.id
       LEFT JOIN activities ON (activities.is_published = 1 AND activities.invoice_id IS NULL AND activities.client_id = clients.id)
       GROUP BY clients.id
       ORDER BY clients.company_name;'],
       
    ['invoices_with_payments',
      'SELECT 
         invoices.id AS invoice_id, 
         IF(SUM(invoice_payments.amount) IS NULL, 0,SUM(invoice_payments.amount)) AS amount_paid 
       FROM invoices 
       LEFT JOIN invoice_payments ON invoice_payments.invoice_id = invoices.id 
       GROUP BY invoices.id'
    ],
    
    ['invoices_with_totals',
     'SELECT 
         invoices.id, invoices.client_id, invoices.comments, invoices.issued_on, invoices.is_published, invoices.created_at, invoices.updated_at, 
         IF(SUM(activities.cost) IS NULL, 0,SUM(activities.cost)) AS amount,
         invoices_with_payments.amount_paid,
         IF(IF(SUM(activities.cost) IS NULL, 0,SUM(activities.cost))-invoices_with_payments.amount_paid = 0, true,false) AS is_paid
       FROM invoices 
       LEFT JOIN activities ON activities.invoice_id = invoices.id
       LEFT JOIN invoices_with_payments ON invoices_with_payments.invoice_id = invoices.id
       GROUP BY invoices.id;']
  ]

  def self.migrate_indexes_with(m)
    CREATE_INDEXES.each_pair{|t,cols| cols.each{|c| self.send m, t, c }}
  end
  
  def self.up
    migrate_indexes_with :add_index

    CREATE_VIEWS.each { |view_def| execute( 'CREATE OR REPLACE VIEW %s AS %s' %  [view_def[0], view_def[1]] ) }
  end
  
  def self.down
    migrate_indexes_with :remove_index
    
    CREATE_VIEWS.reverse.each{|view_def| execute "DROP VIEW IF EXISTS #{view_def[0]};" }
  end
end