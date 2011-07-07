class Activity < ActiveRecord::Base
  include ExtensibleObjectHelper
  include MoneyModelHelper

  money :cost, :currency => false
  money :tax,  :currency => false
  
  belongs_to :client
  belongs_to :invoice
  
  validates_presence_of :activity_type
  
  # Since we've switched to acts_as_money, these two validations are no longer needed, since acts_as money guarantee's
  # the nmericality... But - they don't hurt, so I'll keep them here.
  validates_numericality_of :cost, :allow_nil => true
  validates_numericality_of :tax,  :allow_nil => true
  
  before_destroy :ensure_not_published
  
  def initialize(*args)
    super(*args)
  end
  
  def label
    (self.activity_type.nil? or self.activity_type.length == 0) ? "Activity" : self.activity_type.capitalize
  end
  
  attr_accessor :dont_validate_type_associations
  def validate
    activity_type_sym = (activity_type.nil? or activity_type.empty?) ? nil : activity_type.to_sym
    
    unless dont_validate_type_associations or !self.class.reflections.has_key?(activity_type_sym)
      type_association = self.send activity_type_sym

      if type_association.nil?
        errors.add activity_type_sym, 'missing'
      else
        type_association.valid?
        type_association.errors.each { |attr,msg| errors.add attr, msg }
      end

    end
  end

  before_save do |record| 
    activity_type_sym = (record.activity_type.nil? or record.activity_type.empty?) ? nil : record.activity_type.to_sym
    
    if record.class.reflections.has_key?(activity_type_sym)
      type_association = record.send activity_type_sym
    
      type_association.save if type_association and type_association.changed?
    end
  end
  
  def is_paid?
    (invoice.nil?) ? false : invoice.is_paid?
  end
  
  def is_published?
    (invoice.nil?) ? false : invoice.is_published
  end
  
  def ensure_not_published
    if is_published?
      errors.add_to_base "Can't destroy an activity once its invoice is published"
      return false
    end
  end
  
  def validate_on_update
    errors.add_to_base "Activity can't be adjusted once its invoice is published" if ( 
      # If we're published, and someone's trying to change us ....
      is_published? and changed_attributes.length > 0 and 
      # *But* this change isn't the case of an invoice association from nil to (not nil) [this case is cool]:
      !(changed_attributes.length == 1 and changed_attributes.keys.include? "invoice_id" and invoice_id_change[0].nil?)
    )
  end
  
  def sub_activity
    send activity_type unless activity_type.nil?
  end
  
  def authorized_for?(options)
    return true unless options.try(:[],:action)
    
    case options[:action].to_s
      when /^(edit|delete)$/
        (is_published?) ? false : true
      else
        true
    end
  end
  
  def move_to_invoice(dest)        
    dest_invoice = (dest.class == Integer) ? Invoice.find(dest) : dest

    raise StandardError, "Can't move an already-published activity." if is_published?
    raise StandardError, "Can't move an activity to an already published invoice." if dest_invoice.try(:is_published?)

    if dest_invoice.nil?
      self.invoice_id =  nil

      # OMG - this took me forever to figure out. It *seems* there's some bug in rails 2.3.8 that's 
      # causing this not to update from the above statement, when we're setting the association to nil
      # Weirder still - this only happens when transactions are enabled. (Such as when we're in test:units!)
      @changed_attributes["invoice_id"] = nil
    else
      self.invoice_id = (dest_invoice.nil?) ? nil : dest_invoice.id
      self.client_id = dest_invoice.client_id
    end

    @dont_validate_type_associations = true
    save!
    @dont_validate_type_associations = false
  end
 
  handle_extensions
end
