require 'rbconfig'

class InstanceGenerator < Rails::Generator::Base
  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])
  
  DATABASES = %w( mysql )
  
  MYSQL_SOCKET_LOCATIONS = [
    "/tmp/mysql.sock",                        # default
    "/var/run/mysqld/mysqld.sock",            # debian/gentoo
    "/var/tmp/mysql.sock",                    # freebsd
    "/var/lib/mysql/mysql.sock",              # fedora
    "/opt/local/lib/mysql/mysql.sock",        # fedora
    "/opt/local/var/run/mysqld/mysqld.sock",  # mac + darwinports + mysql
    "/opt/local/var/run/mysql4/mysqld.sock",  # mac + darwinports + mysql4
    "/opt/local/var/run/mysql5/mysqld.sock"   # mac + darwinports + mysql5
  ]

  default_options :db => "mysql", :shebang => DEFAULT_SHEBANG, :freeze => false

  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    usage("Databases supported for preconfiguration are: #{DATABASES.join(", ")}") if (options[:db] && !DATABASES.include?(options[:db]))
    @destination_root = args.shift
  end

  def manifest
    # The absolute location of the BriskBills files
    root = File.expand_path BRISKBILLS_ROOT
    
    # Use /usr/bin/env if no special shebang was specified
    script_options     = { :chmod => 0755, :shebang => options[:shebang] == DEFAULT_SHEBANG ? nil : options[:shebang] }
    dispatcher_options = { :chmod => 0755, :shebang => options[:shebang] }
    
    record do |m|
      # Root directory
      m.directory ""
      
      # Standard files and directories
      base_dirs = %w(config config/environments db log script public vendor/plugins)
      text_files = %w(CHANGELOG COPYING COPYING.LESSER INSTALL README)
      environments = Dir["#{root}/config/environments/*.rb"]
      scripts = Dir["#{root}/script/**/*"].reject { |f| f =~ /(destroy|generate|plugin)$/ }
      public_files = ["public/.htaccess"] + Dir["#{root}/public/**/*"]
      
      files = base_dirs + text_files + environments + scripts + public_files
      files.map! { |f| f = $1 if f =~ %r{^#{root}/(.+)$}; f }
      files.sort!
      
      files.each do |file|
        case
        when File.directory?("#{root}/#{file}")
          m.directory file
        when file =~ %r{^script/}
          m.file brisk_bills_root(file), file, script_options
        when file =~ %r{^public/dispatch}
          m.file brisk_bills_root(file), file, dispatcher_options
        else
          m.file brisk_bills_root(file), file
        end
      end
      
      # script/generate
      m.file "instance_generate", "script/generate", script_options
      
      # database.yml and .htaccess
      m.template "databases/#{options[:db]}.yml", "config/database.yml", :assigns => {
        :app_name => File.basename(File.expand_path(@destination_root)),
        :socket   => options[:db] == "mysql" ? mysql_socket_location : nil
      }

      # Instance Rakefile
      m.file "instance_rakefile", "Rakefile"

      # Instance Configurations
      m.file "instance_routes.rb", "config/routes.rb"
      m.template "instance_environment.rb", "config/environment.rb", :assigns => {
        :brisk_bills_environment => File.join(File.dirname(__FILE__), 'templates', brisk_bills_root("config/environment.rb")),
        :app_name => File.basename(File.expand_path(@destination_root))
      }
      m.template "instance_boot.rb", "config/boot.rb"
      
      # Install Readme
      m.readme brisk_bills_root("INSTALL")
    end
  end

  protected

    def banner
      "Usage: #{$0} /path/to/brisk-bills/app [options]"
    end

    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("-r", "--ruby=path", String,
             "Path to the Ruby binary of your choice (otherwise scripts use env, dispatchers current path).",
             "Default: #{DEFAULT_SHEBANG}") { |v| options[:shebang] = v }
      opt.on("-d", "--database=name", String,
            "Preconfigure for selected database (options: #{DATABASES.join(", ")}).",
            "Default: mysql") { |v| options[:db] = v }
    end
    
    def mysql_socket_location
      RUBY_PLATFORM =~ /mswin32/ ? MYSQL_SOCKET_LOCATIONS.find { |f| File.exists?(f) } : nil
    end

  private

    def brisk_bills_root(filename = '')
      File.join("..", "..", "..", "..", filename)
    end
  
end
