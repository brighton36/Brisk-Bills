['021_create_views_and_indexes.rb', '022_create_client_financial_transactions.rb', '024_updates_for_sales_tax.rb'].each do |m|
  require [RAILS_ROOT,'db','migrate', m].join "/"
end

class MoneyToCents < ActiveRecord::Migration
  
  CONVERT_FIELDS = {
    Activity => [:cost, :tax],
    EmployeeClientLaborRate => :hourly_rate,
    Payment => :amount,
    InvoicePayment => :amount
  }

  CREATE_VIEWS = [
    ['clients_with_charges_sum', 
     'SELECT 
        invoices.client_id,
        SUM(IF(activities.cost_in_cents IS NULL, 0,activities.cost_in_cents)+IF(activities.tax_in_cents IS NULL, 0, activities.tax_in_cents)) AS charges_sum_in_cents
      FROM invoices
      LEFT JOIN activities ON activities.invoice_id = invoices.id
      GROUP BY invoices.client_id;'],
    
    ['clients_with_payment_sum',
     'SELECT 
         payments.client_id, 
         SUM(payments.amount_in_cents) AS payment_sum_in_cents
       FROM payments
       GROUP BY payments.client_id;'],
    
    ['clients_with_balances',
     'SELECT
         clients.*,
         SUM(IF(activities.cost_in_cents IS NULL, 0,activities.cost_in_cents)+IF(activities.tax_in_cents IS NULL, 0, activities.tax_in_cents)) AS uninvoiced_activities_balance_in_cents,
         clients_with_charges_sum.charges_sum_in_cents,
         IF(clients_with_payment_sum.payment_sum_in_cents IS NULL, 0,clients_with_payment_sum.payment_sum_in_cents) AS payment_sum_in_cents,
         (
            clients_with_charges_sum.charges_sum_in_cents -
            IF(clients_with_payment_sum.payment_sum_in_cents IS NULL, 0,clients_with_payment_sum.payment_sum_in_cents)
         ) AS balance_in_cents
       FROM clients
       LEFT JOIN clients_with_charges_sum ON clients_with_charges_sum.client_id = clients.id
       LEFT JOIN clients_with_payment_sum ON clients_with_payment_sum.client_id = clients.id
       LEFT JOIN activities ON (activities.is_published = 1 AND activities.invoice_id IS NULL AND activities.client_id = clients.id)
       GROUP BY clients.id
       ORDER BY clients.company_name;'],
       
    ['invoices_with_payments',
      'SELECT 
         invoices.id AS invoice_id, 
         IF(SUM(invoice_payments.amount_in_cents) IS NULL, 0,SUM(invoice_payments.amount_in_cents)) AS amount_paid_in_cents
       FROM invoices 
       LEFT JOIN invoice_payments ON invoice_payments.invoice_id = invoices.id 
       GROUP BY invoices.id'
    ],
    
    ['invoices_with_totals',
     'SELECT 
         invoices.id, invoices.client_id, invoices.comments, invoices.issued_on, invoices.is_published, invoices.created_at, invoices.updated_at, 
         SUM(IF(activities.cost_in_cents IS NULL, 0,activities.cost_in_cents)+IF(activities.tax_in_cents IS NULL, 0, activities.tax_in_cents)) AS amount_in_cents,
         invoices_with_payments.amount_paid_in_cents,
         IF(SUM(IF(activities.cost_in_cents IS NULL, 0,activities.cost_in_cents)+IF(activities.tax_in_cents IS NULL, 0, activities.tax_in_cents))-invoices_with_payments.amount_paid_in_cents = 0, true,false) AS is_paid
       FROM invoices 
       LEFT JOIN activities ON activities.invoice_id = invoices.id
       LEFT JOIN invoices_with_payments ON invoices_with_payments.invoice_id = invoices.id
       GROUP BY invoices.id;'],
       
    ['client_finance_transactions_union', 
     "SELECT 
        CONCAT('invoice',invoices_with_totals.id) AS id,
        client_id, 
        issued_on AS date, 
        CONCAT('Invoice ',invoices_with_totals.id) AS description, 
        amount_in_cents*-1 AS amount_in_cents
      FROM invoices_with_totals
      UNION 
      SELECT 
        CONCAT('payment',payments.id) AS id,
        client_id, 
        paid_on AS date, 
        CONCAT('Payment - ',payment_methods.name, IF(payments.payment_method_identifier IS NULL,'',CONCAT(' ',payments.payment_method_identifier))) AS description, 
        amount_in_cents
      FROM payments
      LEFT JOIN payment_methods ON payment_methods.id = payments.payment_method_id;"],
      
    # This is lame, nothing really 'changed' here  - I just have to re-create this view apparently
    ['client_finance_transactions', 'SELECT * FROM client_finance_transactions_union ORDER BY date DESC;']
  ]
  
  # This returns for us the most recent 'version' of a view, as found by going through the old migrations
  def self.prior_view_definitions
    ret = []
    
    [ ::CreateViewsAndIndexes, ::CreateClientFinancialTransactions, ::UpdatesForSalesTax ].each do |migration|
      migration.const_get(:CREATE_VIEWS).each do |vp|
        existing_pair = ret.find{|ret_vp| ret_vp[0] == vp[0] }
        
        if existing_pair
          ret[ret.index existing_pair][1] = vp[1]
        else
          ret << vp
        end
      end
    end
  
    ret
  end

  def self.up
    CONVERT_FIELDS.each_pair do |klass, cols|
      cols.to_a.each do |col|
        klass.update_all('%s = %s * 100' % (col.to_s.to_a * 2) )
        change_column klass.table_name, col, :integer
        rename_column klass.table_name, col, ('%s_in_cents' % col.to_s ).to_sym 
      end
    end

    say_with_time "Updating Views" do
      CREATE_VIEWS.each { |vd| execute( 'CREATE OR REPLACE VIEW %s AS %s' %  [vd[0], vd[1]] ) }
    end
  end

  def self.down
    CONVERT_FIELDS.each_pair do |klass, cols|
      cols.to_a.each do |col|
        rename_column klass.table_name, ('%s_in_cents' % col.to_s ).to_sym, col
        change_column klass.table_name, col, :decimal,  :precision => 10, :scale => 2
        klass.update_all('%s = %s / 100' % (col.to_s.to_a * 2) )
      end
    end
    
    # Revert to the old views, for the ones that changed...
    self.prior_view_definitions.reject{ |vd| 
      CREATE_VIEWS.find{|cvd| cvd[0] == vd[0]}.nil?
    }.each{|view_def| execute 'ALTER VIEW %s AS %s' %  [view_def[0], view_def[1]]  }
  end
end
