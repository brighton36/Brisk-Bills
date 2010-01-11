namespace :brisk_bills do
  desc "Initiliaze a new Billing System Database"

  task :first_time_setup => :environment do  
    require 'pp'

    class UserAbort < StandardError; end

    def agree_to?(msg)
      begin print msg end until /^(y[e]?[s]?|n[o]?)$/i.match STDIN.gets.downcase.chomp      
      ($1 =~ /^y/) ? true : false
    end
   
    # Let's get started !
    begin
      puts I18n.t(:first_time_setup_welcome)
      
      envconf = HashWithIndifferentAccess.new ActiveRecord::Base.configurations[RAILS_ENV]
      
      # Have the User Confirm the config
      puts I18n.t(:first_time_setup_confirm_env)
      envconf.each_pair {|k,v| puts "  %s: %s" % [k,v]}
      
      raise UserAbort, I18n.t(:first_time_setup_user_abort) unless agree_to? I18n.t(:first_time_setup_confirm_env_prompt)
  
      # Empty Password? let's discourage them from continuing:
      raise UserAbort, I18n.t(:first_time_setup_user_abort) unless envconf[:password] =~ /.+/ or agree_to? I18n.t(:first_time_setup_empty_pass)

      begin
      db_version = ActiveRecord::Migrator.current_version
      rescue
      end

      # Make sure we can connect. If not - try to create the db and user
      raise UserAbort, I18n.t(
        :first_time_setup_connection_fail, 
        :sql => [
          "CREATE DATABASE `%s`;" % envconf[:database],
          "USE `%s`;" % envconf[:database],
          "GRANT ALL PRIVILEGES ON `%s`.* TO `%s`@`%s` IDENTIFIED BY '%s';" % [envconf[:database], envconf[:username],envconf[:host],envconf[:password]]
        ].join ("\n  ")
      ) if db_version.nil?
      
      # Let's run migrations?
      if db_version == 0 
        raise UserAbort, I18n.t(:first_time_setup_user_abort) unless agree_to? I18n.t(:first_time_setup_run_migration_prompt)

        Rake::Task['db:migrate'].invoke

        puts I18n.t(:first_time_setup_migration_complete)
      end

      # Create the first employee?
      if Employee.count(:all) == 0 and agree_to? I18n.t(:first_time_setup_create_first_employee)
        begin
          puts I18n.t(:first_time_setup_employee_enter)
          
          employee_fields = [
          I18n.t(:first_time_setup_first_name),
          I18n.t(:first_time_setup_last_name),
          I18n.t(:first_time_setup_email),
          I18n.t(:first_time_setup_password)
          ]
          
          employee_values = []
          
          indent_width = employee_fields.sort{|a,b| a.size <=> b.size }.last.size
          
          employee_fields.each_with_index do |field,i|
            print "%#{indent_width + 4}s: " % field
            employee_values[i] = STDIN.gets.chomp
          end
  
          puts I18n.t(:first_time_setup_first_employee_msg)
          
          employee_fields.each_with_index {|k,i| puts "  %#{indent_width+2}s: %s" % [k,employee_values[i]]}
           
         end until agree_to? I18n.t(:first_time_setup_first_employee_confirm)
         
         Employee.create!(
          :first_name => employee_values[0],
          :last_name => employee_values[1],
          :email_address => employee_values[2],
          :password => employee_values[3],
          :login_enabled => true
         )
      end

      puts I18n.t(:first_time_setup_complete)
    
      rescue UserAbort
        puts $!
        exit
    end
  end
end