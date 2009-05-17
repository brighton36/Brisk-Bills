class Admin::ClientRepresentativesController < ApplicationController
  include AdminLayoutHelper
  include ExtensibleObjectHelper

  active_scaffold :client_representative do |config|
    config.label = "Client Representatives"

    config.columns = [:clients, :first_name, :last_name, :title, :cell_phone, :password, :login_enabled, :accepts_tos_version, :email_address, :notes, :created_at, :updated_at]
    
    config.columns[:clients].form_ui = :select
    columns[:clients].sort_by :sql => 'clients.company_name'

    config.columns[:email_address].includes = [:credential]
    config.columns[:email_address].sort_by :sql => "credentials.email_address"

    config.columns[:title].label = 'Job Title'

    config.list.columns = [:clients, :last_name, :first_name, :email_address]
    
    config.create.columns = config.update.columns = [:first_name, :last_name, :email_address, :password, :login_enabled, :title, :cell_phone, :clients, :notes]
    
    config.list.sorting = [{:clients => :asc},{:last_name => :asc},{:first_name => :asc}]
  end

  # This fixes a weirdo activescaffold(?) bug in lib/nested.rb that causes a redirect loop when going from nested to list, in production mode...
  def verify_action(options)
    super(options) unless options[:only] == :add_existing
  end

  handle_extensions
end
