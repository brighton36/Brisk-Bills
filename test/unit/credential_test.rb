require File.dirname(__FILE__) + '/../test_helper'

class CredentialTest < ActiveSupport::TestCase

  def setup
    if Setting.exists? :account_lockout_threshold
      Setting.set! :account_lockout_threshold, 3
    else  
      Setting.create!(
      :keyname     => 'account_lockout_threshold',
      :label       => 'Account Lockout Threshold',
      :description => 'Number of incorrect logins before an account is locked out',
      :keyval      => '3'
      )
    end

    if Setting.exists? :account_lockout_duration
      Setting.set! :account_lockout_duration, 54000
    else
      Setting.create!(
      :keyname     => 'account_lockout_duration',
      :label       => 'Account Lockout Duration',
      :description => 'Number of seconds for an account to be locked out, after the lockout threshold has been reached',
      :keyval      => '54000'
      ) 
    end

  end

  # Replace this with your real tests.
  def test_has_credential_helpers
    [Employee, ClientRepresentative].each do |user_klass|
      jsmith = user_klass.create!(
        :first_name    => 'John', 
        :last_name     => 'Smith', 
        :email_address => 'jsmith@test.com', 
        :password      => 'password'
      )

      assert_equal 'jsmith@test.com', jsmith.credential.email_address
      assert_equal 'jsmith@test.com', jsmith.email_address
      
      assert_not_equal 'password', jsmith.credential.password_hash
      assert_not_equal 'password', jsmith.password_hash
  
      assert_not_equal 0, jsmith.credential.password_hash.length
      assert_not_equal 0, jsmith.password_hash.length
        
      assert_equal false, jsmith.credential.login_enabled
      
      jsmith_cred = Credential.find :first, :conditions => ['email_address = ? ','jsmith@test.com']
  
      assert_equal user_klass.to_s, jsmith_cred.user.class.to_s
      assert_equal jsmith.id, jsmith_cred.user.id
      
      jsmith.destroy
    end

  end

  def test_logins
    Employee.create!(
      :first_name    => 'George', 
      :last_name     => 'Washington', 
      :email_address => 'gwashington@whitehouse.gov',
      :password      => 'cherrytree',
      :login_enabled => false
    )

    Employee.create!(
      :first_name    => 'John', 
      :last_name     => 'Adams', 
      :email_address => 'jadams@whitehouse.gov',
      :password      => 'sedition',
      :login_enabled => true
    )
    
    Employee.create!(
      :first_name    => 'Thomas', 
      :last_name     => 'Jefferson', 
      :email_address => 'tjefferson@whitehouse.gov',
      :password      => 'monticello',
      :login_enabled => true
    )
    
    Employee.create!(
      :first_name    => 'James', 
      :last_name     => 'Madison', 
      :email_address => 'jmadison@whitehouse.gov',
      :password      => '$5000',
      :login_enabled => true
    )
    
    # Make sure find_user_using_auth works
    assert_nothing_raised do
      assert_not_nil Credential.find_using_auth( 'tjefferson@whitehouse.gov', 'monticello' )
    end

    # Make sure wrong password doesn't work
    assert_nothing_raised do
      assert_nil Credential.find_using_auth( 'tjefferson@whitehouse.gov', 'crackattack!' )
    end

    # Make sure we can't login if the login is disabled...
    assert_raise CredentialDisabled do
      Credential.find_using_auth 'gwashington@whitehouse.gov', 'cherrytree'
    end
  end
    
  def test_humanize_duration_in_seconds
    # Probably this is silly - but whatever
    [
      [1,    '1 second'],
      [45,   '45 seconds'],
      [60,   '1 minute'],
      [3600, '1 hour'],
      [3601, '1 hour 1 second'],
      [777,  '12 minutes 57 seconds'],
      [3661, '1 hour 1 minute 1 second'],
      [7200, '2 hours'],
      [7260, '2 hours 1 minute'],
      [7325, '2 hours 2 minutes 5 seconds'],
      [100000, '27 hours 46 minutes 40 seconds']
    ].each do |t|
      assert_equal t[1], Credential.humanize_duration_from_seconds(t[0])
    end
  end
    
  def test_lockout
    Employee.create!(
      :first_name    => 'James', 
      :last_name     => 'Monroe', 
      :email_address => 'jmonroe@whitehouse.gov',
      :password      => 'florida',
      :login_enabled => true
    )

    # We'll use this to simulate the advancement of the clock:
    time_now = Time.now
    time_now = Time.local time_now.year, time_now.month, time_now.day, time_now.hour, time_now.min, time_now.sec # Removes usec's

    args_crack = %w(jmonroe@whitehouse.gov crackattack!)
    args_valid = %w(jmonroe@whitehouse.gov florida)

    2.times do 
      assert_nothing_raised{ Credential.find_using_auth(*args_crack+[time_now]) } 
    end

    # Ensure we throw a lockout error
    assert_raise(CredentialLockedOut) { Credential.find_using_auth(*args_crack+[time_now]) }

    # Ensure we throw a lockout error despite this pass being right
    assert_raise(CredentialLockedOut) { Credential.find_using_auth(*args_valid+[time_now]) }
    
    # Do a success round to clear out the failures from above
    time_now += 54000 # sleep
    assert_nothing_raised{ Credential.find_using_auth(*args_valid+[time_now]) } 
    
    # Cause a lock-out
    2.times { Credential.find_using_auth(*args_crack+[time_now]) }
    
    assert_raise(CredentialLockedOut) { Credential.find_using_auth(*args_crack+[time_now]) }
    
    # Now we sleep out the multiplier
    time_now += 54000 # sleep
    
    # Cause another lockout
    2.times { Credential.find_using_auth(*args_crack+[time_now]) }
    assert_raise(CredentialLockedOut) { Credential.find_using_auth(*args_crack+[time_now]) }
    
    time_now += 54000 # sleep
    
    # Despite being past the duration, this should nonetheless fail b/c of the multiplier
    assert_raise(CredentialLockedOut) { Credential.find_using_auth(*args_valid+[time_now]) }
  end
  
  def test_password_reset
    dvader = Employee.create!(
      :first_name    => 'Darth', 
      :last_name     => 'Vader', 
      :email_address => 'dvader@deathstar.com',
      :password      => 'iamyourfather',
      :login_enabled => true
    )
    
    valid_reset_token = nil
    
    # Test Generation:
    assert_nothing_raised{ valid_reset_token = dvader.credential.generate_reset_token! }
    
    assert_not_nil valid_reset_token
    
    assert_match /^[a-z0-9]{32}$/i, valid_reset_token
    
    # Test use:
    assert_equal false, dvader.credential.reset_password_by_token!( '????', 'badnewpassword')
    
    assert_equal true, dvader.credential.reset_password_by_token!(valid_reset_token, 'darkside')
    
    assert_not_nil Credential.find_using_auth('dvader@deathstar.com', 'darkside')

    # Test Lockout:
    assert_nothing_raised do
      valid_reset_token = dvader.credential.generate_reset_token!

      2.times{ assert_equal false, dvader.credential.reset_password_by_token!('????', 'badnewpassword') } 
    end

    # Ensure we throw a lockout error on next attempt:
    assert_raise(CredentialLockedOut) { dvader.credential.reset_password_by_token!( '????', 'badnewpassword') }

    # And make sure we continue to fail, now that they're locked out, even if we use a good token:
    assert_raise(CredentialLockedOut) { dvader.credential.reset_password_by_token! valid_reset_token, 'badnewpassword' }

  end
  
end
