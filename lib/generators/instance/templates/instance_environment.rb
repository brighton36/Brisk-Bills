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
  
  config.load_paths << "#{BRISKBILLS_ROOT}/app/model_views"

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
  
  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_brisk-bills_session',
    :secret      => <% require 'digest/sha1' %>'<%= Digest::SHA1.hexdigest("--#{app_name}--#{Time.now.to_s}--#{rand(10000000)}--") %>'
  }
  
  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql
  
  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  # We really don't do any I18n right now, this is a hack to fix some of the date formatting issues that popped up in rails 2.3
  config.i18n[:load_path] << "#{BRISKBILLS_ROOT}/config/locale/en.rb"
  
  config.after_initialize do
    # Add new inflection rules using the following format:
    ActiveSupport::Inflector.inflections do |inflect|
      inflect.uncountable 'config'
    end
  end
end

ActionMailer::Base.delivery_method = :sendmail
