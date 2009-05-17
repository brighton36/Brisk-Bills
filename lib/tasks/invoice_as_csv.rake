namespace :brisk_bills do
  desc "Print an invoice to STDOUT as a csv file"
  
  task :invoice_as_csv => :environment do   
    require 'fastercsv'

    inv_id = $1.to_i if /^([\d]+)$/.match ENV['id']

    unless inv_id
       puts "Missing required id= parameter"
       exit
    end

    inv = Invoice.find inv_id

    unless inv
       puts "Invoice not found"
       exit
    end

    csv_out = FasterCSV.generate do |csv|
      csv << %w(Qty Rate Amount Item Date Description)

      inv.activities.find(:all, :order => 'occurred_on ASC').each do |a| 
        csv << a.sub_activity.as_legacy_ledger_row
      end

    end

    puts csv_out
  end
end
