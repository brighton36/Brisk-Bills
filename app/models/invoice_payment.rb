class InvoicePayment < ActiveRecord::Base
  belongs_to :payment
  belongs_to :invoice
end
