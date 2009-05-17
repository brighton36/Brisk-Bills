class ClientFinancialTransaction < ActiveRecord::Base
  # NOTE: This whole thing is kind of a hack...
  # We're not a *real* model, we're just an ActiveRecord class around a view thats useful 
  self.table_name = 'client_finance_transactions'

  belongs_to :client

  def readonly?
    true
  end
end
