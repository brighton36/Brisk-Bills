class InvoicesWithTotal < Invoice
  # NOTE: I really hate that I have to create a wrapper-model this way, but, it seems to work ok for now I guess ...
  # Maybe I could put this into a plugin or something ... let's see
  # Or even just taking these out of the models folder would be great, maybe even into the controller's .rb
  # This is a little too crappy, but, whatev for now ...

  self.table_name = 'invoices_with_totals'

  def create(*args)    
    invoice_assign_and_save! Invoice.new
  end
  
  def update
    invoice_assign_and_save! Invoice.find(id)
  end
  
  def destroy
    inv = Invoice.find(id)
    inv.destroy
  end
  
  def invoice_assign_and_save!(inv)
    invoice_columns = Invoice.columns.collect{|c| c.name}-['id']

    inv.activity_type_ids = activity_type_ids
    
    attributes.reject{|k,v| true unless invoice_columns.include? k }.each{ |k,v| inv.send "#{k}=", v }

    inv.save!

    inv.errors.each { |attr,msg| errors.add attr, msg }
    
    inv
  end
  
  def amount_paid
    Money.new read_attribute(:amount_paid_in_cents).to_i
  end

  def amount
    Money.new read_attribute(:amount_in_cents).to_i
  end
  
  def is_paid?
    (read_attribute(:is_paid).to_i == 1) ? true : false
  end

end