module Factory
  def self.create_labor(attributes = {}, activity_attributes = {})
    employee = Employee.find(
      :first, 
      :conditions => ['credentials.email_address = ? ', 'chris@derosetechnologies.com'], 
      :include => [:credential]
    )
    employee ||= self.create_employee

    l = Activity::Labor.new(
      { 
      :employee => employee,
      :comments => 'Performed productivity enhancing work.',
      :duration => 60
      }.merge(attributes) 
    )

    assign_sub_activity l, activity_attributes

    raise StandardError unless l.save!
    
    l    
  end
  
  def self.create_material(attributes = {}, activity_attributes = {})
    m = Activity::Material.new(
      {
      :label => 'Expensive Widget',
      :comments => 'Brand-new straight from the factory.'
      }.merge(attributes) 
    )

    assign_sub_activity m, {:cost => 849.99, :tax => 51.00 }.merge(activity_attributes)

    raise StandardError unless m.save!
    
    m
  end
  
  def self.create_proposal(attributes = {}, activity_attributes = {})
    p = Activity::Proposal.new(
      {
      :label => 'Driveway Repavement',
      :comments => 'Includes top quality asphault...',
      :proposed_on => (DateTime.now << 1) # one month ago ...
      }.merge(attributes) 
    )

    assign_sub_activity p, {:cost => 1200.0, :tax => 20.01 }.merge(activity_attributes)

    raise StandardError unless p.save!
    
    p
  end
  
  def self.create_adjustment(attributes = {}, activity_attributes = {})
    a = Activity::Adjustment.new(
      {
      :label => 'Starting Balance',
      :comments => 'Before we moved to the amazing Brisk Bills!'
      }.merge(attributes) 
    )

    assign_sub_activity a, {:cost => 300.0, :tax => 0 }.merge(activity_attributes)

    raise StandardError unless a.save!
    
    a
  end
  
  def self.create_client(attributes = {})
    company_name = (attributes.has_key?(:company_name)) ? attributes[:company_name] : 'ACME Fireworks'
    
    client = Client.find :first, :conditions => ['company_name = ?', company_name]
    
    (client) ? client : Client.create!(
      {
      :company_name => 'ACME Fireworks',
      :address1     => '470 S. Andrews Ave.',
      :address2     => 'Suite 206', 
      :phone_number => '954-942-7703',
      :fax_number   => '954-942-7933' 
      }.merge(attributes)
    )
  end
  
  def self.create_employee(attributes = {})
    Employee.create!( 
      {
      :first_name      => 'Chris',
      :last_name       => 'DeRose',
      :email_address   => 'chris@derosetechnologies.com',
      :phone_extension => 69
      }.merge(attributes)
    )
  end
  
  def self.assign_sub_activity( model , passed_attributes)

    attributes = {} 
    attributes[:is_published] = true     unless passed_attributes.has_key? :is_published
    attributes[:occurred_on]  = DateTime.now unless passed_attributes.has_key? :occurred_on
    
    unless passed_attributes.has_key? :client or passed_attributes.has_key? :client_id
      attributes[:client] = Client.find :first, :conditions => ['company_name = ?', 'ACME Fireworks']
      attributes[:client] ||= self.create_client
    end

    model.activity.attributes = attributes.merge(passed_attributes) 
  end


  def self.generate_invoice(client, total, attributes = {})
    attributes[:issued_on] ||= Time.now
    attributes[:is_published] = true if !attributes.has_key?(:is_published) or attributes[:is_published].nil?

    activity_increments = (total.floor).to_f/10
    1.upto(10) do |i|
      activity_amount = activity_increments
      activity_amount += total - total.floor if i == 1 
      
      # Tax-related test adjustments:
      activity_tax = (activity_amount * 0.25).floor
      activity_cost = activity_amount-activity_tax

      a = Activity::Adjustment.new :label => 'test invoice'
      a.activity.cost = activity_cost.to_money
      a.activity.tax = activity_tax
      a.activity.client = client
      a.activity.occurred_on = (attributes[:issued_on] - 1.months)
      a.activity.is_published = true
      a.save! 
    end

    activity_types = ActivityType.find(:all)
    
    puts "\nWARNING: No activity types found in db... sure you're using the right fixtures?\n" unless activity_types.length >0

    Invoice.create!( 
      { 
      :activity_types => activity_types, 
      :client => client,
      :payment_assignments => (attributes[:is_published]) ? client.recommend_payment_assignments_for(total) : [],
      :activities => Invoice.recommended_activities_for(client, attributes[:issued_on], activity_types)
      }.merge(attributes)
    )
    
  end
  
  def self.generate_payment(client, amount, attributes = {})
    Payment.create!(
      {
      :client => client,
      :amount => amount,
      :payment_method_id => 1,
      :invoice_assignments => client.recommend_invoice_assignments_for(amount),
      }.merge(attributes)
    )
  end

end