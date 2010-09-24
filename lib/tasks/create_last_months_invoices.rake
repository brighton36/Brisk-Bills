namespace :brisk_bills do
  desc "Create a batch of invoices for the prior month, on all accounts with an uninvoiced balance"
  
  task :create_last_months_invoices => :environment do
    end_of_last_month = Time.utc(*Time.now.to_a).last_month.end_of_month
 
    invoiceable_client_ids = Activity.find(
      :all, 
      :select => 'DISTINCT client_id', 
      :conditions => [
        [
        'is_published = ?',
        'invoice_id IS NULL',
        'client_id IS NOT NULL', 
        'occurred_on <= ?'
        ].join(' AND '),
        true,
        end_of_last_month
      ]
    ).collect{|a| a.client.id}
    
    if invoiceable_client_ids.length > 0
      all_activity_types = ActivityType.find(:all)
      
      Client.find(:all, :conditions => ['id IN (?)', invoiceable_client_ids], :order => 'company_name ASC').each do |client|
        puts "Creating invoice for client \"#{client.company_name}\"..."
        
        inv = Invoice.create!(
           :client => client, 
           :activity_types => all_activity_types,
           :activities => Invoice.recommended_activities_for client.id, end_of_last_month, all_activity_types
        )
        
        puts "  Created: id (%d) amount: $%s" % [
          inv.id,
          ('%.2f' % inv.amount).gsub(/(\d)(?=\d{3}+(\.\d*)?$)/, '\1,')
        ]
      end
    end
    
  end
end
