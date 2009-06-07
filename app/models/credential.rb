require "digest/sha2"

class CredentialLockedOut < StandardError; end
class CredentialDisabled < StandardError; end
  
class Credential < ActiveRecord::Base
  validates_confirmation_of :password,  :if => :perform_password_validation?
  validates_presence_of :password_hash, :if => :login_enabled, :message => "can't be blank if login is enabled"
  
  validates_uniqueness_of :email_address

  attr_reader :password
  
  def password=(val)
    @password = val
    
    self.password_hash = self.class.salt_and_hash(password) unless self.password.blank?
  end
  
  belongs_to :user, :polymorphic => true

  def self.salt_and_hash(password)
    begin
      @salt = Rails.configuration.authentication_salt
    rescue
      @salt = "Salt is missing - No Salt is a bad idea!"
      logger.error @salt # cheeky?
    end unless @salt

    Digest::SHA256.hexdigest( "%s%s" % [password, @salt] )
  end

  def self.find_using_auth(email, password, find_at = Time.now)
    credential = Credential.find(:first, :conditions => ['email_address = ?', email])

    (credential and credential.accept_password?(password, find_at)) ? credential : nil
  end

  def self.find_by_email(email_address)
    Credential.find :first, :conditions => ['email_address = ?', email_address]
  end
  
  def self.humanize_duration_from_seconds(seconds)
    # I did it this way so we can test easier
    until_citation = [
      (seconds/3600).floor,
      ((seconds % 3600)/60).floor,
      (seconds % 60)
    ]

    {0 => 'hour', 1 => 'minute', 2 => 'second'}.each_pair do |i, unit|
      until_citation[i] = '%d %s' % [
        until_citation[i], 
        ((until_citation[i] > 1) ? unit.pluralize : unit)
      ] if until_citation[i] and until_citation[i] > 0
    end
    
    until_citation.reject!{|i| i.nil? or i == 0 }
    
    until_citation.join ' '
  end
  
  def locked_out?(find_at)
    account_lockout_threshold > 0 and
    failed_login_at and
    (failed_login_count % account_lockout_threshold) == 0 and 
    locked_until(find_at) > 0
  end
  
  def locked_until(find_at)
    # NOTE: There's a multiplier effect here. So, if the lockout_threshold is 3, and there's been 12 unsuccessful logins
    # we're not going to let them in for another 4*lockout_duration seconds

    # How long we've been locked out for
    been_locked_out_for = (find_at - failed_login_at).seconds
    
    lockout_multiplier = (failed_login_count / account_lockout_threshold).floor
    
    account_lockout_duration * lockout_multiplier - been_locked_out_for
  end

  def accept_password?(password, find_at)
    password_security_transaction!(
      password_hash == self.class.salt_and_hash(password), 
      find_at
    ) { self.reset_password_token = nil }
  end
  
  def generate_reset_token!
    raise_on_disabled
    
    char_pool = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a

    token = Array.new(32){char_pool[rand(char_pool.size-1)]}.join
    
    self.reset_password_token = token
    reset_failed_login_fields
    save!
    
    token
  end
  
  def reset_password_by_token!(supplied_token, newpassword, find_at = Time.now)
    password_security_transaction!(supplied_token == reset_password_token, find_at) do 
      self.password = newpassword
      self.reset_password_token = nil
    end
  end

  def default_post_login_url_to
    # NOTE: This should be different for non-admins when we get around to it ...
    { :controller => 'admin/activities', :action => 'index' }
  end

  def is_request_permitted?(controller, action)
    # NOTE: Highly rudimentary, but until we want to do the public side and proper ACLs, this will work.
    user_type == 'Employee'
  end

  def self.guest_permitted?(controller,action)
    # These are controller/actions that don't require auth to access. Probably these acl type questions should go into their own models eventually
    controller == 'authentication'
  end

  private

  def password_security_transaction!(success, find_at) 
    # This is used by accept_password? and reset_password_by_token!
    # Essentialy if conditional is true - then we reset our lockout counters and execute the block, if conditional is false we 
    # increment failure counters. Regardless, we return the conditional status. These methods looked so similar I thought I'd DRY
    # them out a bit
    
    raise_on_disabled

    unless locked_out?(find_at)
      if success
        yield if block_given?
        reset_failed_login_fields
      else
        bad_login(find_at)
      end
      
      save! if changed?
      
      return true if success
    end
    
    raise_on_locked_out(find_at)
    
    return false
  end

  def raise_on_disabled
    raise CredentialDisabled, "Your account is currently disabled from logging in." if !login_enabled
  end
  
  def raise_on_locked_out(find_at)
    raise CredentialLockedOut, (
      'Your account has been locked out due to too many unsuccessful login attempts. '+
      "Please wait another #{self.class.humanize_duration_from_seconds(locked_until(find_at))} before trying again."
    ) if locked_out?(find_at)
  end

  def reset_failed_login_fields
    self.failed_login_count = 0
    self.failed_login_at = nil
  end
  
  def bad_login(find_at)
    self.failed_login_count += 1
    self.failed_login_at = find_at
  end

  def perform_password_validation?
    self.new_record? ? true : !self.password.blank?
  end
  
  # NOTE We do this to keep from pulling this information four times from the databaase during an authentication request
  def account_lockout_threshold
    grab_settings unless @lockout_threshold
    @lockout_threshold
  end
  
  def account_lockout_duration
    grab_settings unless @lockout_duration
    @lockout_duration
  end
  
  def grab_settings
    ( @lockout_threshold, @lockout_duration ) = Setting.grab :account_lockout_threshold, :account_lockout_duration
    
    @lockout_duration = @lockout_duration.to_i
    @lockout_threshold = @lockout_threshold.to_i
  end
end
