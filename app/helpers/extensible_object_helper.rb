require 'find'

module ExtensibleObjectHelper 
  
  def self.append_features(base) # :nodoc:
    super
    base.extend ClassMethods
  end
  
  module ClassMethods

    def handle_extensions      
      /^(#{BRISKBILLS_ROOT}.+)\.rb\:[\d]+/.match caller[0]
      
      extension_directory = $1
      
      Find.find(extension_directory) do |f| 
        # Don't traverse sub-directories:
        Find.prune if f != extension_directory and File.directory?(f)

        require_dependency f if /#{extension_directory}\/.+\.rb$/.match f 
      end if File.directory? extension_directory
      
    end    

  end
  
end