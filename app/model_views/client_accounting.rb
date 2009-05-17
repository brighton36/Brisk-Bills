class ClientAccounting < Client
  # NOTE: I really hate that I have to create a mode, this way, but, it seems to work ok ...
  
  self.table_name = 'clients_with_balances'
end
