class Client < ActiveRecord::Base
  include IsActiveModelHelper
  
  has_and_belongs_to_many :client_representatives, :join_table => 'client_representatives_clients', :uniq => true
  
  has_many :client_eventlogs
  has_many :activities
  has_many :invoices
  has_many :payments
  
  has_many :employee_client_labor_rates, :class_name => 'EmployeeClientLaborRate', :dependent => :destroy
  
  has_many :client_financial_transactions
  
  before_destroy :ensure_not_referenced_on_destroy
  
  validates_presence_of :company_name

  def name
    self.company_name
  end
  
  def uninvoiced_activities_balance
    Activity.sum( Invoice::ACTIVITY_TOTAL_SQL, :conditions => ['client_id = ? AND is_published = ? AND invoice_id IS NULL',id, true] ) or 0.0
  end
  
  def balance
    Money.new( 
      Client.find(
      :first, 
      :select => [
        'id',
        'company_name',
        '(
         IF(charges.charges_sum_in_cents IS NULL, 0,charges.charges_sum_in_cents) - 
         IF(deposits.payment_sum_in_cents IS NULL, 0, deposits.payment_sum_in_cents)
        ) AS sum_difference_in_cents'
      ].join(', '),
      :joins => [
        "LEFT JOIN(
          SELECT invoices.client_id, SUM(#{Invoice::ACTIVITY_TOTAL_SQL}) AS charges_sum_in_cents 
            FROM invoices 
            LEFT JOIN activities ON activities.invoice_id = invoices.id 
            GROUP BY invoices.client_id
        ) AS charges ON charges.client_id = clients.id",
        
        'LEFT JOIN (
          SELECT payments.client_id, SUM(payments.amount_in_cents) AS payment_sum_in_cents
            FROM payments 
            GROUP BY payments.client_id
        ) AS deposits ON deposits.client_id = clients.id '
      ].join(' '),
      :conditions => [ 'clients.id = ?', id]
      ).sum_difference_in_cents.to_i
    ) unless id.nil?
  end
  
  def ensure_not_referenced_on_destroy
    errors.add_to_base "Can't destroy a referenced employee" and return false unless authorized_for? {:destroy}
  end
  
  def authorized_for?(options)
    case options[:action]
      when :destroy
        [Invoice, Payment, Activity].each{ |k| return false if k.count(:all, :conditions => ['client_id = ?', id] ) > 0 }

        true
      else
        true
    end
  end
  
  def mailing_address
    ret = []
    
    %w(name address1 address2).each do |f|
      val = send(f.to_sym) and ( ret <<val if val.length )
    end

    ret << '%s%s %s' % [
      (city.nil? or city.length == 0) ? '' : "#{city}, ", 
      state, 
      zip
    ]

    ret
  end

end