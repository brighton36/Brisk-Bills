class CreateCredentialsMigrateRepresentatives < ActiveRecord::Migration
  
  USER_TABLES = [:client_representatives, :employees]
  
  def self.user_tables_find(find_args = {})
    # To Keep it DRY down there ...
    USER_TABLES.collect{ |t| t.to_s.classify.constantize.find(:all, find_args) }.flatten
  end

  def self.up
    
    # Phase 1: Since we're here - habtm the client_representatives
    say_with_time "Migrating Client Representatives" do 
      # Create the Representatives to clients habtm relationship
      create_table( :client_representatives_clients, :id => false ) do |t|
        t.integer :client_id, :client_representative_id
      end
      
      add_index :client_representatives_clients, :client_id
      add_index :client_representatives_clients, :client_representative_id
  
      # This is possibly a cheesy way to do it, but it'll work ok enough, I think:
      clients_map = [] # Largely minimizes sql lookups
      curr_cr = nil    # keeps track of what we're working on

      # Reassign the client_id to the habtm
      ClientRepresentative.find(
        :all, 
        :select => 'id, email_address, client_id',
        :order => 'email_address'
      ).each do |cr|

        client_id = cr[:client_id]       

        if curr_cr.nil? or (curr_cr[:email_address] != cr[:email_address])
          curr_cr = cr
        else
          ClientRepresentative.delete cr.id
        end

        clients_map[client_id] = Client.find client_id unless clients_map[client_id]

        curr_cr.clients << clients_map[client_id] if clients_map[client_id] # Its possible this client doesn't exist
      end

      # Remove the :client_id column from the reps table
      remove_column :client_representatives, :client_id
    end
    
    # Phase 2: Credentials themselves
    
    say_with_time "Migrating Credentials" do 
      
      # First we create the credentials table:
      create_table( :credentials) do |t|
        t.string :email_address, :password_hash
                
        t.integer :failed_login_count, :null => false, :default => 0
        t.timestamp :failed_login_at
  
        t.boolean :login_enabled, :default => 0, :null => false
  
        t.references :user, :polymorphic => true
  
        t.timestamps
      end
  
      # Then we create 'disabled' credentials to the reps/employees ...
      user_tables_find(:select => 'id, email_address').each do |u|
        u.create_credential :email_address => u[:email_address], :login_enabled => 0
      end
  
      # Remove the  :email column from the reps table
      USER_TABLES.each{ |t| remove_column t, :email_address }
    end

    # Phase 3: Add some credential related settings while we're here:
    Setting.create!(
      :keyname     => 'account_lockout_threshold',
      :label       => 'Account Lockout Threshold',
      :description => 'Number of incorrect logins before an account is locked out',
      :keyval      => '3'
    )
    
    Setting.create!(
      :keyname     => 'account_lockout_duration',
      :label       => 'Account Lockout Duration',
      :description => 'Number of seconds for an account to be locked out, after the lockout threshold has been reached',
      :keyval      => '900'
    )
  end

  def self.down
  
    # Phase 2:
    say_with_time "Downgrading Credentials" do 
      USER_TABLES.each{ |t| add_column t, :email_address, :string }
      
      ClientRepresentative.reset_column_information
      Employee.reset_column_information
      
      user_tables_find(:select => 'id, email_address, credential.*', :include => [:credential]).each do |u|
        u[:email_address] = u.credential.email_address and u.save! if u.credential
      end
      
    end

    # Phase 1:
    say_with_time "Downgrading Client Representatives" do 
      add_column :client_representatives, :client_id, :integer
      
      ClientRepresentative.reset_column_information
      
      ClientRepresentative.find(:all, :include => :clients).each do |cr|
        cr[:client_id] = cr.client_ids[0]
        cr.save!
      end
    end
    
    # Now we remove our settings
    say_with_time "Removing Credential Settings" do 
      Setting.find( 
        :all, 
        :conditions => { :keyname => %w(account_lockout_threshold account_lockout_duration) }
      ).each{|s| s.destroy }
    end

    drop_table :credentials

    drop_table :client_representatives_clients
      
  end
end
