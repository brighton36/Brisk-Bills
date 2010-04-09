class InvoicePayment < ActiveRecord::Base
  include MoneyModelHelper
  
  belongs_to :payment
  belongs_to :invoice
  
  money :amount, :currency => false
end
