class ClientAccounting < Client
  # NOTE: I really hate that I have to create a model, this way, but, it seems to work ok ...
  
  self.table_name = 'clients_with_balances'
  
  def uninvoiced_activities_balance
    Money.new read_attribute(:uninvoiced_activities_balance_in_cents).to_i
  end
  
  def balance
    Money.new read_attribute(:balance).to_i
  end
end
