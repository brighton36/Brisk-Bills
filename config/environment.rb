# Be sure to restart your server when you modify this file

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# We'll use this during bootup
SECRETS_FILE = "#{RAILS_ROOT}/config/secrets.yml"

# And I need this included before the initializer ends too
require 'yaml'

BriskBills::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  config.action_controller.session = { 
    :session_key => "_briskbills_session",
    :secret => YAML::load(IO.read(SECRETS_FILE))["session_secret"]
  }  unless SECRETS_FILE.nil?

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  # Add new inflection rules using the following format
  # (all these examples are active by default):
  # Inflector.inflections do |inflect|
  #   inflect.plural /^(ox)$/i, '\1en'
  #   inflect.singular /^(ox)en/i, '\1'
  #   inflect.irregular 'person', 'people'
  #   inflect.uncountable %w( fish sheep )
  # end
end

ActionMailer::Base.delivery_method = :sendmail