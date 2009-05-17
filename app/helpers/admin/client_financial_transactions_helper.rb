module Admin::ClientFinancialTransactionsHelper
  include ExtensibleObjectHelper
  
  def amount_column(record)
    h_money record.amount, false
  end
  
  handle_extensions
end
