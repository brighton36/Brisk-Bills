BRISKBILLS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..")) unless defined? BRISKBILLS_ROOT

unless defined? BriskBills::Version
  module BriskBills::Version
    Major = '0'
    Minor = '6'
    Tiny  = '0'

    class << self
      def to_s
        [Major, Minor, Tiny].join('.')
      end
      
      alias :to_str :to_s
    end
  end
end
