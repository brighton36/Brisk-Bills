class CreateActivityTypes < ActiveRecord::Migration
  def self.up
    create_table( :activity_types, :options => 'TYPE=InnoDB') do |t|
      t.string  :label
      
      t.timestamps
    end
    
    # Create invoice_activity_types for habtm
    create_table( :invoices_activity_types, :options => 'TYPE=InnoDB', :id => false ) do |t|
      t.integer :invoice_id, :activity_type_id
    end
    
    add_index :invoices_activity_types, [:invoice_id, :activity_type_id]

    activity_types = []
    
    say_with_time "Populating initial activities ..." do
      # Now create the initial entries:
      activity_models_path = RAILS_ROOT+'/app/models/activity'    

      Find.find(activity_models_path) do |a| 
        activity_types << ActivityType.create( :label => $1.capitalize ) if /^#{activity_models_path}\/([^\/]+)\.rb$/.match a
      end
    end

    # Adjust all the pre-existing invoices to reflect the new activity_types habtm the way they should
    say_with_time "Associating existing invoices with activity types" do
      Invoice.find(:all).each { |inv| activity_types.each{ |a| inv.activity_types << a } }
    end
  end

  def self.down
    drop_table :activity_types
    drop_table :invoices_activity_types
  end
end
