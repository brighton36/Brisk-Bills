require 'libpptable'
namespace :brisk_bills do
  desc "Check for inconsistencies in the invoice & payment assignments"
  
  task :payment_assignment_consistency_check => :environment do
    
    # NOTE: One way to 'fix' any problems with your invoice assignments is to: 
    #   InvoicePayment.find(:all).each{|ip| ip.destroy}
    #   Payment.find(:all).each{|pmt| if pmt.amount > Money.new(0) then pmt.invoice_assignments = pmt.client.recommend_invoice_assignments_for(pmt.amount); pmt.save! end }
    # But, keep in mind that this basically destroys all the associations you may have worked so hard on...

    # We use this as a helper for each test below 
    def db_check(name, &block)
      print ' - %s...' % name
      records = block.call

      puts (records.length > 0) ? 
        ("ERROR: %d records Found" % records.length) : 
        "PASS"
    end
    
    pp_table(
      ["Table", "Record Count"],      
      [Invoice,Payment,InvoicePayment,Activity,Client].collect{|klass|
        [klass.table_name, klass.count]
      }
    )
    
    puts 
    puts "Tests: "
    
    # Test : Check for InvoicePayments <= 0
    db_check 'Testing for assignments with an invalid amount' do
      InvoicePayment.find(:all, :conditions => ['amount_in_cents <= 0'])
    end
    
    # Test : Check for InvoicePayments which are orphaned from an invoice or payment
    #        (This means NULL or an id to a payment/invoice that's not in the db
    db_check 'Testing for assignments with an NULL payment_id or invoice_id' do    
      InvoicePayment.find(
        :all, 
        :conditions => ['invoice_id IS NULL OR payment_id IS NULL']
      )
    end
    
    db_check 'Testing for assignments with a missing payment or invoice' do
      InvoicePayment.find(
        :all, 
        :select => [
          'invoice_payments.id',
          'payments.id AS payment_id',
          'invoices.id AS invoice_id'
          ].join(','),
        :joins => [
          'LEFT JOIN payments ON invoice_payments.payment_id = payments.id',
          'LEFT JOIN invoices ON invoice_payments.invoice_id = invoices.id'
          ].join(' '),
        :conditions => [
          'payments.id IS NULL OR invoices.id IS NULL'
        ]
      )
    end

    # Test : Ensure that the InvoicePayments for each invoice don't exceed its total amount  
    db_check "Testing for payments whose assignments exceed the payment total" do
      Payment.find(
        :all,
        :select => [
          'payments.id', 
          'payments.amount_in_cents',
          'ip.allocated_in_cents'
        ].join(','),
        :joins => 'LEFT JOIN (
          SELECT 
            invoice_payments.payment_id, 
            SUM(invoice_payments.amount_in_cents) AS allocated_in_cents 
          FROM invoice_payments 
          GROUP BY invoice_payments.payment_id
        ) AS ip ON ip.payment_id = payments.id ',
        :conditions => 'ip.allocated_in_cents > payments.amount_in_cents'
      )
    end

    # Test : Ensure that the InvoicePayments for each payment don't exceed its total amount
    db_check "Testing for invoices whose assignments exceed the invoice total" do
      # This one gets a little complicated since the invoice totals query is complicated
      # and I don't want to make this query completely ridiculous.
      
      # Generate a map that tracks allocations:
      invoice_allocations = InvoicePayment.find(
        :all, 
        :select => [
          'id',
          'invoice_id',
          'SUM(amount_in_cents) AS allocated_in_cents'
        ].join(' ,'), 
        :group => 'invoice_id'
      ).inject({}){ |ret,ip| ret.merge({ip.invoice_id => ip.allocated_in_cents.to_i}) }
      
      
      Invoice.find_with_totals( :all, :conditions => ['is_published = ?', true] ).find_all{|inv|
        ( 
        invoice_allocations.has_key? inv.id and 
        invoice_allocations[inv.id] > inv.amount_in_cents.to_i
        )
      }
    end
    
  end
end