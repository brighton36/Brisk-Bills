# Don't change this file!
# Configure your app in config/environment.rb and config/environments/*.rb

RAILS_ROOT = File.expand_path("#{File.dirname(__FILE__)}/..") unless defined?(RAILS_ROOT)

module Rails
  class << self
    def vendor_rails?
      File.exist?("#{RAILS_ROOT}/vendor/rails")
    end
  end
end

module BriskBills
  class << self
    def boot!
      unless booted?
        preinitialize
        pick_boot.run
      end
    end

    def booted?
      defined? BriskBills::Initializer
    end

    def pick_boot
      case
      when app?
        AppBoot.new
      when vendor?
        VendorBoot.new
      else
        GemBoot.new
      end
    end

    def vendor?
      File.exist?("#{RAILS_ROOT}/vendor/brisk-bills")
    end
    
    def app?
      File.exist?("#{RAILS_ROOT}/lib/brisk-bills.rb")
    end

    def preinitialize
      load(preinitializer_path) if File.exist?(preinitializer_path)
    end
    
    def loaded_via_gem?
      pick_boot.is_a? GemBoot
    end

    def preinitializer_path
      "#{RAILS_ROOT}/config/preinitializer.rb"
    end
  end

  class Boot
    def run
      load_initializer
    end
    
    def load_initializer
      begin
        require 'brisk-bills'
        require 'brisk-bills/initializer'
      rescue LoadError => e
        $stderr.puts %(BriskBills could not be initialized. #{load_error_message})
        exit 1
      end
      BriskBills::Initializer.run(:set_load_path)
    end
  end

  class VendorBoot < Boot
    def load_initializer
      $LOAD_PATH.unshift "#{RAILS_ROOT}/vendor/brisk-bills/lib" 
      super
    end
        
    def load_error_message
      "Please verify that vendor/brisk-bills contains a complete copy of the BriskBills sources."
    end
  end

  class AppBoot < Boot
    def load_initializer
      $LOAD_PATH.unshift "#{RAILS_ROOT}/lib" 
      super
    end

    def load_error_message
      "Please verify that you have a complete copy of the BriskBills sources."
    end
  end

  class GemBoot < Boot
    def load_initializer
      self.class.load_rubygems
      load_briskbills_gem
      super
    end
      
    def load_error_message
     "Please reinstall the BriskBills gem with the command 'gem install brisk-bills'."
    end

    def load_briskbills_gem
      if version = self.class.gem_version
        gem 'brisk-bills', version
      else
        gem 'brisk-bills'
      end
    rescue Gem::LoadError => load_error
      $stderr.puts %(Missing the BriskBills #{version} gem. Please `gem install -v=#{version} rails`, update your BRISKBILLS_GEM_VERSION setting in config/environment.rb for the Rails version you do have installed, or comment out BRISKBILLS_GEM_VERSION to use the latest version installed.)
      exit 1
    end

    class << self
      def rubygems_version
        Gem::RubyGemsVersion if defined? Gem::RubyGemsVersion
      end

      def gem_version
        if defined? BRISKBILLS_GEM_VERSION
          BRISKBILLS_GEM_VERSION
        elsif ENV.include?('BRISKBILLS_GEM_VERSION')
          ENV['BRISKBILLS_GEM_VERSION']
        else
          parse_gem_version(read_environment_rb)
        end
      end

      def load_rubygems
        require 'rubygems'

        unless rubygems_version >= '0.9.4'
          $stderr.puts %(BriskBills requires RubyGems >= 0.9.4 (you have #{rubygems_version}). Please `gem update --system` and try again.)
          exit 1
        end

      rescue LoadError
        $stderr.puts %(BriskBills requires RubyGems >= 0.9.4. Please install RubyGems and try again: http://rubygems.rubyforge.org)
        exit 1
      end

      def parse_gem_version(text)
        $1 if text =~ /^[^#]*BRISKBILLS_GEM_VERSION\s*=\s*["']([!~<>=]*\s*[\d.]+)["']/
      end

      private
        def read_environment_rb
          File.read("#{RAILS_ROOT}/config/environment.rb")
        end
    end
  end
end

# All that for this:
BriskBills.boot!