class UpdatesForSalesTax < ActiveRecord::Migration

  CREATE_VIEWS = [
    ['clients_with_charges_sum', 
     'SELECT 
        invoices.client_id,
        SUM(IF(activities.cost IS NULL, 0,activities.cost)+IF(activities.tax IS NULL, 0, activities.tax)) AS charges_sum
      FROM invoices
      LEFT JOIN activities ON activities.invoice_id = invoices.id
      GROUP BY invoices.client_id;'],
        
    ['clients_with_balances',
     'SELECT
         clients.*,
         SUM(IF(activities.cost IS NULL, 0,activities.cost)+IF(activities.tax IS NULL, 0, activities.tax)) AS uninvoiced_activities_balance,
         clients_with_charges_sum.charges_sum,
         IF(clients_with_payment_sum.payment_sum IS NULL, 0,clients_with_payment_sum.payment_sum) AS payment_sum,
         (
            clients_with_charges_sum.charges_sum -
            IF(clients_with_payment_sum.payment_sum IS NULL, 0,clients_with_payment_sum.payment_sum)
         ) AS balance
       FROM clients
       LEFT JOIN clients_with_charges_sum ON clients_with_charges_sum.client_id = clients.id
       LEFT JOIN clients_with_payment_sum ON clients_with_payment_sum.client_id = clients.id
       LEFT JOIN activities ON (activities.is_published = 1 AND activities.invoice_id IS NULL AND activities.client_id = clients.id)
       GROUP BY clients.id
       ORDER BY clients.company_name;'],
       
    ['invoices_with_totals',
     'SELECT 
         invoices.id, invoices.client_id, invoices.comments, invoices.issued_on, invoices.is_published, invoices.created_at, invoices.updated_at, 
         SUM(IF(activities.cost IS NULL, 0,activities.cost)+IF(activities.tax IS NULL, 0, activities.tax)) AS amount,
         invoices_with_payments.amount_paid,
         IF(SUM(IF(activities.cost IS NULL, 0,activities.cost)+IF(activities.tax IS NULL, 0, activities.tax))-invoices_with_payments.amount_paid = 0, true,false) AS is_paid
       FROM invoices 
       LEFT JOIN activities ON activities.invoice_id = invoices.id
       LEFT JOIN invoices_with_payments ON invoices_with_payments.invoice_id = invoices.id
       GROUP BY invoices.id;']
  ]
  
  def self.replace_views(views)
    views.each { |vd| execute( 'CREATE OR REPLACE VIEW %s AS %s' %  [vd[0], vd[1]] ) }
  end
  
  def self.up
    add_column :activities, :tax, :decimal, :precision => 10, :scale => 2, :default => nil, :null => true

    say_with_time "Updating Views" do
      replace_views CREATE_VIEWS
    end

    say_with_time "Creating Tax Settings" do 
      Setting.create!(
        :keyname     => 'sales_tax_percent',
        :label       => 'Sales Tax %',
        :description => 'Sales Tax Percentage. The added tax percentage against the item price.',
        :keyval      => '6'
      )

      Setting.create!(
        :keyname     => 'sales_tax_flat',
        :label       => 'Sales Flat (flat)',
        :description => 'A flat tax amount added to the item price, independant of the actual cost.',
        :keyval      => '0'
      )
    end

  end
  
  
  def self.down
   
    say_with_time "Updating Views" do
      updated_view_names = CREATE_VIEWS.collect{|v| v[0]}
      
      replace_views CreateViewsAndIndexes::CREATE_VIEWS.select{|v| true if updated_view_names.include? v[0] }.reverse
    end    

    remove_column :activities, :tax

    say_with_time "Removing Tax Settings" do 
      Setting.find( 
        :all, 
        :conditions => { :keyname => %w(sales_tax_percent sales_tax_flat) }
      ).each{|s| s.destroy }
    end

  end
end