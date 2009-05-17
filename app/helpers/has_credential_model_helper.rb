module HasCredentialModelHelper 
  
  %w(email_address password password_hash login_enabled).each do |accessor|
    define_method accessor.to_sym do      
      credential.send accessor.to_sym if credential
    end
    
    setter_method = "#{accessor}=".to_sym
    
    define_method setter_method do |val|
      build_credential unless credential

      credential.send setter_method, val
    end
  end

  def credential_after_save
    credential.save! if credential.changed?
  end

  def validate_credential_fields
    credential.errors.each{|attr,msg| errors.add attr, msg } unless credential.valid?
    validate_without_credentials
  end

  def self.append_features(base)
    super

    base.class_eval do
      has_one :credential, :as => :user, :dependent => :destroy
      
      after_save :credential_after_save
      
      
      alias validate_without_credentials validate
      alias validate validate_credential_fields
    end
  end  
end