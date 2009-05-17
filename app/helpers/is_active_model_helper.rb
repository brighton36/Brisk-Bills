module IsActiveModelHelper 


  def initialize(*args)
    super(*args)
    
    is_active = true if new_record?
  end
  
  def self.append_features(base)
    super
    
    base.class_eval do
      def self.find_active(*args)
        args[1] ||= {}
    
        conditions = args[1][:conditions]
    
        if conditions.class == String
          conditions = ['is_active = ? AND '+conditions,true]
        elsif (
          conditions.respond_to?(:length) and 
          conditions.length > 0 and 
          conditions[0].class == String and 
          conditions[0].length > 0
        )
          conditions = [ 'is_active = ? AND '+conditions[0], true ] + conditions[1..conditions.length]
        else
          conditions = [ 'is_active = ?', true ]
        end
    
        args[1][:conditions] = conditions
    
        self.find(*args)
      end 
      
    end
  end
  
end