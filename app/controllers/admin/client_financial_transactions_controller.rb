class Admin::ClientFinancialTransactionsController < ApplicationController
  include AdminLayoutHelper
  include ExtensibleObjectHelper

  active_scaffold :client_financial_transaction do |config|
    config.show.link = nil
    config.search.link = nil
    config.create.link = nil
    config.update.link = nil
    config.delete.link = nil
    
    config.label = "Posted Financial Transactions"

    config.columns = [:client, :description, :amount, :date]

    config.list.sorting = [{:date => :desc}]

  end

  handle_extensions
end
