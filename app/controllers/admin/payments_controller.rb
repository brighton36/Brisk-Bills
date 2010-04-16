class Admin::PaymentsController < ApplicationController
  include AdminLayoutHelper
  include ExtensibleObjectHelper

  active_scaffold :payment do |config|
    config.label = "Payments"

    config.columns = [:paid_on, :client, :payment_method, :payment_method_identifier, :amount, :created_at, :updated_at]

    config.columns[:client].form_ui = :select
    config.columns[:client].sort_by :sql => 'clients.company_name'
    
    config.columns[:payment_method].form_ui = :select
    config.columns[:payment_method].sort_by :sql => 'payment_methods.name'
    
    config.columns[:payment_method_identifier].description = 'Last four card digits, check number...'
    config.columns[:payment_method_identifier].label = 'Method Identifier'
    
    config.columns[:amount].sort_by :sql => 'amount_in_cents'
    
    config.list.columns =[:client, :payment_method, :amount, :paid_on]
    config.list.sorting = [{:paid_on => :desc}]

    config.create.columns = config.update.columns = [:paid_on, :client, :payment_method, :payment_method_identifier, :amount]
    
    config.update.link = nil
  end

  handle_extensions
end
