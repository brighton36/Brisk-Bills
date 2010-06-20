require [BRISKBILLS_ROOT,'db','migrate', '028_money_to_cents.rb'].join "/"

class InvoicesWithTotalsViewAdjustment < ActiveRecord::Migration
  AMOUNT_IN_CENTS = 'SUM(IF(activities.cost_in_cents IS NULL, 0,activities.cost_in_cents)+IF(activities.tax_in_cents IS NULL, 0, activities.tax_in_cents))'
  
  # THe only reason we had to adjust this was to change the amount_paid_in_cents = 0 to amount_paid_in_cents <= 0
  CREATE_VIEWS = [
    ['invoices_with_totals',
     'SELECT 
         invoices.id, invoices.client_id, invoices.comments, invoices.issued_on, invoices.is_published, invoices.created_at, invoices.updated_at, 
         %s AS amount_in_cents,
         invoices_with_payments.amount_paid_in_cents,
         IF(%s-invoices_with_payments.amount_paid_in_cents <= 0, true,false) AS is_paid
       FROM invoices 
       LEFT JOIN activities ON activities.invoice_id = invoices.id
       LEFT JOIN invoices_with_payments ON invoices_with_payments.invoice_id = invoices.id
       GROUP BY invoices.id;' % [AMOUNT_IN_CENTS,AMOUNT_IN_CENTS] ],
  ]
  
  def self.up
    CREATE_VIEWS.each { |vd| execute( 'CREATE OR REPLACE VIEW %s AS %s' %  [vd[0], vd[1]] ) }
  end

  def self.down
    old_invoices_with_totals = MoneyToCents.const_get(:CREATE_VIEWS).find{|view| view[0] == 'invoices_with_totals'}
    
    execute 'CREATE OR REPLACE VIEW %s AS %s' %  [old_invoices_with_totals[0], old_invoices_with_totals[1]]
  end
end
