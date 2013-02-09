BRISKBILLS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..")) unless defined? BRISKBILLS_ROOT

unless defined? BriskBills::Version
  module BriskBills::Version
    Major = '0'
    Minor = '8'
    Tiny  = '1'

    class << self
      def to_s
        [Major, Minor, Tiny].join('.')
      end
      
      alias :to_str :to_s
    end
  end
end
