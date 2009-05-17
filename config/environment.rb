# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# We'll use this during bootup
SECRETS_FILE = "#{RAILS_ROOT}/config/secrets.yml"

# And I need this included before the initializer ends too
require 'yaml'

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  config.load_paths << "#{RAILS_ROOT}/app/model_views"

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

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  config.active_record.timestamped_migrations = false

  # Add new inflection rules using the following format
  # (all these examples are active by default):
  # Inflector.inflections do |inflect|
  #   inflect.plural /^(ox)$/i, '\1en'
  #   inflect.singular /^(ox)en/i, '\1'
  #   inflect.irregular 'person', 'people'
  #   inflect.uncountable %w( fish sheep )
  # end

  # We really don't do any I18n right now, this is a hack to fix some of the date formatting issues that popped up in rails 2.3
  config.i18n[:load_path] << '%s/config/locale/en.rb' % RAILS_ROOT
end

ActionMailer::Base.delivery_method = :sendmail



# This just helps in a couple places, and I'm putting it here.
class String
  def to_re
    source, options = ( /^\/(.*)\/([^\/]*)$/.match(self) )? [$1, $2] : [self,nil]
    
    mods = 0
    
    options.each_char do |c| 
      mods |= case c
        when 'i': Regexp::IGNORECASE
        when 'x': Regexp::EXTENDED
        when 'm': Regexp::MULTILINE
      end
    end unless options.nil? or options.empty?
        
    Regexp.new source, mods
  end
end
