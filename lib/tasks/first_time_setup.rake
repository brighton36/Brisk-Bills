
namespace :brisk_bills do
  desc "Initiliaze a new Billing System Database" 
  task :first_time_setup => :environment do  
    require 'pp'

    USER_ABORT_MSG = "\nNo problem! Go ahead and edit the '#{RAILS_ROOT}/config/database.yml' file to match your preference, and re-run this task.\nIf you don't like running in the #{RAILS_ENV.inspect} environment, then run this task with the appropriate RAILS_ENV parameter."

    puts "TODO: Welcome notice\n"
    
    current_config = ActiveRecord::Base.configurations[RAILS_ENV]
    
    puts "I see we're running in the #{RAILS_ENV.inspect} environment, with the following settings:"
    current_config.each_pair do |k,v|
      puts "  %s: %s" % [k,v]
    end
    
    begin
      print "Is this the database environment and configuration you wish to create/use? (Y/N) : "
    end until /^(y[e]?[s]?|n[o]?)$/.match STDIN.gets.downcase.chomp

    if $1 =~ /^n/ then puts USER_ABORT_MSG; exit; end
    
    if current_config[:password].nil? or current_config[:password].empty?
      begin
        print "Your password is empty! That doesn't look right... You sure you want to continue? (Y/N) : "
      end until /^(y[e]?[s]?|n[o]?)$/.match STDIN.gets.downcase.chomp
    end
    
    if $1 =~ /^n/ then puts USER_ABORT_MSG; exit; end
    
    # TODO: Make sure we can connect. If not - try to create the db and user
    
    pp ActiveRecord::Base.connected?
    
    # TODO: Make sure we're migrated, If not - migrate!
    
    # TODO: Create the first employee!

  end
end