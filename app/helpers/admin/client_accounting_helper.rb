module Admin::ClientAccountingHelper
  include ExtensibleObjectHelper
  
  def client_balance_column(record)
    h_money record.balance, true
  end
  
  def client_uninvoiced_activities_balance_column(record)
    h_money record.uninvoiced_activities_balance, true
  end
 
  handle_extensions
end
