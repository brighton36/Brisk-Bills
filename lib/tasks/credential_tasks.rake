
namespace :brisk_bills do
  desc "Reset Credential Password" 
  task :credential_password_reset => :environment do  
    active_credential = nil
    new_password = nil
    
    # Get the email address:
    begin
      print "Enter Credential's e-mail address: "
      email_address = STDIN.gets.chomp

      active_credential = Credential.find :first, :conditions => ['email_address = ?',email_address]
      
      raise StandardError, "Credential %s not found." % email_address if active_credential.nil?
    rescue
      puts $!
      puts 
      retry
    end
  
    # Get the password:
    begin
      print "Enter new password : "
      new_password = STDIN.gets.chomp

      print "Verify new password: "
      verify_password = STDIN.gets.chomp
      
      raise StandardError, "Password mismatch!" unless new_password == verify_password
    rescue
      puts $!
      puts 
      retry
    end
    
    # Do the reset:
    active_credential.failed_login_count = 0
    active_credential.failed_login_at = nil
    active_credential.password = new_password

    active_credential.save!
    
    puts
    puts "Password Successfully reset!"
  end
end