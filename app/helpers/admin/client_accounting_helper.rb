module Admin::ClientAccountingHelper
  include ExtensibleObjectHelper
  
  def balance_column(record)
    h_money record.balance, true
  end
  
  def uninvoiced_activities_balance_column(record)
    h_money record.uninvoiced_activities_balance, true
  end
 
  handle_extensions
end
