class ClientRepresentative < ActiveRecord::Base
  include HasCredentialModelHelper

  has_and_belongs_to_many :clients, :join_table => 'client_representatives_clients', :uniq => true
  
  validates_presence_of(
    :first_name,
    :unless => Proc.new { |cr| !cr.last_name.nil? and cr.last_name.length > 0 }, 
    :message => " or Last name must be not be blank"
  )
  
  def name
    [
      first_name, last_name
    ].find_all{|x| x.try(:length).try(:>,0)}.join(' ')
  end

  # This is used by the Nested Add_existing control label
  def self.human_name
    'Representative'
  end
end
