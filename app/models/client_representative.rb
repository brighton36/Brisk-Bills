class ClientRepresentative < ActiveRecord::Base
  include HasCredentialModelHelper

  has_and_belongs_to_many :clients, :join_table => 'client_representatives_clients', :uniq => true
  
  validates_presence_of(
    :first_name,
    :unless => Proc.new { |cr| !cr.last_name.nil? and cr.last_name.length > 0 }, 
    :message => " or Last name must be not be blank"
  )
  
  def name
    ret = String.new
    
    ret += self.first_name if !self.first_name.nil? and self.first_name.length > 0
    
    ret += (ret.length > 0) ? " #{self.last_name}" : self.last_name if !self.last_name.nil? and self.last_name.length > 0
    
    ret
  end
  
end
