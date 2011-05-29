module Admin::ClientFinancialTransactionsHelper
  include ExtensibleObjectHelper
  
  def client_financial_transaction_amount_column(record)
    h_money record.amount, false
  end
  
  handle_extensions
end
