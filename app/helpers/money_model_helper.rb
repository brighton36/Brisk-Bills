module MoneyModelHelper
  # THis module provides assistance to models which utilize the rails_money gem
  
  def self.append_features(base)
    super
    
    base.class_eval do
      super
      
      # This prevents a NoMethodError: undefined method `amount_before_type_cast' error when validations kick-in
      def method_missing(symbol, *params)
        if (symbol.to_s =~ /^(.*)_before_type_cast$/)
         send $1
        else
         super
        end
      end
      
    end
  end
end