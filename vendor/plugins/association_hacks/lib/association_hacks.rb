class ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation
  
  alias_method :association_join_without_labor, :association_join unless self.method_defined? :association_join_without_labor

  def association_join 
    association_hacks = (reflection.active_record.respond_to? :association_hacks ) ? reflection.active_record.association_hacks : nil
    
    if association_hacks and association_hacks.has_key?(reflection.name) and association_hacks[reflection.name].respond_to?(:call)
      association_hacks[reflection.name].call(self)
    else
      association_join_without_labor
    end
  end

end

class ActiveRecord::Base
  class << self
    attr_reader :association_hacks

    def hack_an_association_join(name, &generate_association)
      @association_hacks ||= {}
      
      @association_hacks[ name ] = generate_association
    end
  end
end