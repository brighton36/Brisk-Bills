class PaymentMethod < ActiveRecord::Base
  include ExtensibleObjectHelper
  
  validates_presence_of :name
  
  handle_extensions
end
