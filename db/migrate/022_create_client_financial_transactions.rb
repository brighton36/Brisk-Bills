class CreateClientFinancialTransactions < ActiveRecord::Migration
  
  CREATE_VIEWS = [
    ['client_finance_transactions_union', 
     "SELECT 
        CONCAT('invoice',invoices_with_totals.id) AS id,
        client_id, 
        issued_on AS date, 
        CONCAT('Invoice ',invoices_with_totals.id) AS description, 
        amount*-1 AS amount
      FROM invoices_with_totals
      UNION 
      SELECT 
        CONCAT('payment',payments.id) AS id,
        client_id, 
        paid_on AS date, 
        CONCAT('Payment - ',payment_methods.name, IF(payments.payment_method_identifier IS NULL,'',CONCAT(' ',payments.payment_method_identifier))) AS description, 
        amount
      FROM payments
      LEFT JOIN payment_methods ON payment_methods.id = payments.payment_method_id;"],
      
    ['client_finance_transactions', 'SELECT * FROM client_finance_transactions_union ORDER BY date DESC;']
  ]
  
  def self.up    
    CREATE_VIEWS.each { |view_def| execute( 'CREATE OR REPLACE VIEW %s AS %s' %  [view_def[0], view_def[1]] ) }
  end
  
  def self.down    
    CREATE_VIEWS.reverse.each{|view_def| execute "DROP VIEW #{view_def[0]};" }
  end
end
