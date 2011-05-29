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

    # If someone tries a 'delete' when we're nested inside the clients controller,
    # This ensures the habtm relationship is deleted, and not the record 
    config.nested.shallow_delete = true

    config.list.columns = [:clients, :last_name, :first_name, :email_address]
    
    config.create.columns = config.update.columns = [:first_name, :last_name, :email_address, :password, :login_enabled, :title, :cell_phone, :clients, :notes]
    
    config.list.sorting = [{:clients => :asc},{:last_name => :asc},{:first_name => :asc}]
  end

  # We override this method b/c at some point in the new active_scaffold code, there was a bug
  # that stopped this from being smart enough to recognize the :uniq on the client_representatives 
  # association. in he new_existing action
  def merge_conditions(*conditions)    
    if (
      params[:action].to_sym == :new_existing && 
      params.has_key?(:parent_model) && 
      params.has_key?(:eid)
    )
      parent_klass = params[:parent_model].constantize

      # I'm not sure if table_name is the right method to use exactly - but it works here... 
      parent_id = session["as:#{params[:eid]}"][:constraints][parent_klass.table_name.to_sym].to_i if parent_klass

      parent_record = parent_klass.find parent_id if parent_id

      existing_association_ids = parent_record.send('%s_ids' % params[:parent_column].singularize) if parent_record
      
      (existing_association_ids) ? 
        ['`client_representatives`.id NOT IN (?)', existing_association_ids] :
        nil    
    else
      super(*conditions)
    end
  end

  handle_extensions
end
