# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
require File.join(File.dirname(__FILE__), 'boot')

BriskBills::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
  
  # Only load the extensions named here, in the order given. By default all 
  # extensions in vendor/extensions are loaded, in alphabetical order. :all 
  # can be used as a placeholder for all extensions not explicitly named. 
  # config.extensions = [ :all ] 

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug
  
  # Load the translations from the gem repo
  config.i18n.load_path << Dir[File.join(BRISKBILLS_ROOT, 'config', 'locale', '*.{rb,yml}')]
  
  <% 
  # We'll be using this for the random strings down below
  character_pool = (0...255).collect(&:chr).reject{|c| !/[a-z0-9\!\@\#\$\%\^\&\*\(\)\_\+]/i.match c }
  %>

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :key => '_brisk-bills_session',
    :secret      => '<%= ([nil]*54).collect{character_pool[rand(character_pool.length)]}.join%>'
  }
  
  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql
  
  # This is used by the authentication controller, and should be a unique to every database:
  config.authentication_salt = '<%= ([nil]*52).collect{character_pool[rand(character_pool.length)]}.join%>'
end

ActionMailer::Base.delivery_method = :sendmail
