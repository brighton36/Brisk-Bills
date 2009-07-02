
namespace :brisk_bills do
  desc "Initiliaze a new Billing System Database" 
  task :first_time_setup => :environment do  
    require 'pp'

    WELCOME_MSG = <<EOD
TODO!\n
INtructions - If you want to be successul hit 'y' , unless you know what you're doing
EOD
    USER_ABORT_MSG = <<EOD
\nNo problem! Go ahead and edit the '#{RAILS_ROOT}/config/database.yml' file to match your preference, and re-run this task.
If you don't like running in the #{RAILS_ENV.inspect} environment, then run this task with the appropriate RAILS_ENV parameter.
EOD
    ENVIRONMENT_CONFIRM_MSG = <<EOD
I see we're running in the #{RAILS_ENV.inspect} environment, with the following settings:
EOD
    ENVIRONMENT_CONFIRM_PROMPT = "Is this the database environment and configuration you wish to create/use? (Y/N) : "
    EMPTY_PASSWORD_PROMPT = "Your password is empty! That doesn't look right... You want to stop and adjust this? (Y/N) : "
    CONNECTION_FAIL_MSG = <<EOD
Unable to connect to the database server. This could be because:
  * The specified connection/database settings are wrong.
  * The specified database/username does not exist on the SQL server.

Please verify the contents of your '#{RAILS_ROOT}/config/database.yml' file.
Or, if you have access to the database server, run the following SQL commands to create the database and user:
  %s
EOD
    RUN_MIGRATIONS_PROMPT = "Connected to database successfully! Run Migrations? (Y/N) : "
    MIGRATIONS_COMPLETED_MSG = "Migrations Completed Successfully!"
   
    # Let's get started !
    puts WELCOME_MSG
    
    envconf = HashWithIndifferentAccess.new ActiveRecord::Base.configurations[RAILS_ENV]
    
    # Have the User Confirm the config
    puts ENVIRONMENT_CONFIRM_MSG
    envconf.each_pair {|k,v| puts "  %s: %s" % [k,v]}
    
    begin print ENVIRONMENT_CONFIRM_PROMPT end until /^(y[e]?[s]?|n[o]?)$/.match STDIN.gets.downcase.chomp

    if $1 =~ /^n/ then puts USER_ABORT_MSG; exit; end

    # Empty Password? let's discourage them from continuing:
    unless envconf[:password] =~ /.+/
      begin print EMPTY_PASSWORD_PROMPT end until /^(y[e]?[s]?|n[o]?)$/.match STDIN.gets.downcase.chomp
      
      if $1 =~ /^y/ then puts USER_ABORT_MSG; exit; end
    end
    
    # Make sure we can connect. If not - try to create the db and user
    unless ActiveRecord::Base.connected?
      puts CONNECTION_FAIL_MSG % [
        "CREATE DATABASE `%s`;" % envconf[:database],
        "USE `%s`;" % envconf[:database],
        "GRANT ALL PRIVILEGES ON `%s`.* TO %s@%s IDENTIFIED BY '%s';" % [envconf[:database], envconf[:username],envconf[:host],envconf[:password]]
      ].join ("\n  ")

      exit
    end
    
    # TODO ?: 
    # Rake::Task['db:create'].invoke
    
    # Let's run migrations?
    begin print RUN_MIGRATIONS_PROMPT end until /^(y[e]?[s]?|n[o]?)$/.match STDIN.gets.downcase.chomp

    if $1 =~ /^y/
      Rake::Task['db:migrate'].invoke
      puts MIGRATIONS_COMPLETED_MSG
    end
        
    # Create the first employee?
    pp "TODO: employee count"+Employee.count(:all)
    

  end
end