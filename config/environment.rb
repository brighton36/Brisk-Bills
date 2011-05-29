# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

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
  config.plugins = [
    :active_scaffold,
    :active_scaffold_as_gem,
    :active_scaffold_form_observation,
#    :active_scaffold_full_refresh,
    :active_scaffold_move_column_under,
    :acts_as_money,
    :association_hacks,
    'InlineAttachment-0.3.0-modified',
    :railspdf,
    :render_component
  ]


  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  config.action_controller.session = { 
    :key => "_briskbills_session",
    :secret => 'eHqaX)DcVnzAHe2@U7*ZNcgjhFSwMz+s(OQnkd$3!BStoC4NCSIGvX'
  }

  # This is used by the authentication controller, and should be a unique to every database:
  config.authentication_salt = '_SI*0jb%d)YcZSi#fM7hcdW3t3ZUM@Lo$1To6IyUjM0ieBFDnENH'

end

ActionMailer::Base.delivery_method = :sendmail
