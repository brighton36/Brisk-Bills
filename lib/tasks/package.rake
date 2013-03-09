require 'rubygems'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'brisk-bills'

PKG_NAME = 'brisk-bills'
PKG_VERSION = BriskBills::Version.to_s
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"
RUBY_FORGE_PROJECT = PKG_NAME
RUBY_FORGE_USER = ENV['RUBY_FORGE_USER'] || 'brighton36'

RELEASE_NAME  = ENV['RELEASE_NAME'] || PKG_VERSION
RELEASE_NOTES = ENV['RELEASE_NOTES'] ? " -n #{ENV['RELEASE_NOTES']}" : ''
RELEASE_CHANGES = ENV['RELEASE_CHANGES'] ? " -a #{ENV['RELEASE_CHANGES']}" : ''
#RUBY_FORGE_GROUPID = '1337'
#RUBY_FORGE_PACKAGEID = '1638'

RDOC_TITLE = "BriskBills - Invoicing with some kick!"
RDOC_EXTRAS = ['README', 'INSTALL', "CHANGELOG", "COPYING","COPYING.LESSER", 'bin/brisk-bills', 'app']
RDOC_EXCLUDES = ['lib/generators']

namespace 'package' do
  spec = Gem::Specification.new do |s|
    s.name = PKG_NAME
    s.version = PKG_VERSION
    s.author = "Chris DeRose, DeRose Technologies, Inc."
    s.email = 'cderose@derosetechnologies.com'
    s.description = s.summary = "A full-featured, rails-based system for basic accounting, with a particular focus on invoicing and automatic bill generation."
    s.homepage = 'http://www.derosetechnologies.com/community/brisk-bills'
        
    s.rubyforge_project = RUBY_FORGE_PROJECT
    s.platform = Gem::Platform::RUBY
    s.bindir = 'bin'
    s.executables = (Dir['bin/*'] + Dir['scripts/*']).map { |file| File.basename(file) }
    
    s.add_dependency 'rake',        '>= 0.8.3'
    s.add_dependency 'extensions',  '>= 0.6.0'
    s.add_dependency 'pdf-writer',  '>= 1.1.8'
    s.add_dependency 'slimtimer4r', '>= 0.2.4'
    s.add_dependency 'money',       '>= 2.2.0'
    s.add_dependency 'mysql',       '>= 2.7'
    s.add_dependency 'rails',       '= 2.3.17'
    s.add_dependency 'i18n',        '= 0.4.2'

    s.has_rdoc = true
    s.rdoc_options = [
      '--title', RDOC_TITLE, '--line-numbers', '--main', 'README'
    ]+RDOC_EXCLUDES.collect{|e| ['--exclude', e] }.flatten

    s.extra_rdoc_files = RDOC_EXTRAS
    
    files = FileList['**/*']
    files.exclude '**/._*'
    files.exclude '**/*.rej'
    files.exclude '*.sql'
    files.exclude '.git*'
    files.exclude /^cache/
    files.exclude 'config/database.yml'
    files.exclude 'config/locomotive.yml'
    files.exclude 'config/lighttpd.conf'
    files.exclude 'config/mongrel_mimes.yml'
    files.exclude 'db/*.db'
    files.exclude /^doc/
    files.exclude 'log/*.log'
    files.exclude 'log/*.pid'
    files.exclude /^pkg/
    files.exclude /\btmp\b/
    files.exclude 'radiant.gemspec'
    files.include 'public/.htaccess'
    files.include 'log/.keep' # A cheap/easy way of making sure the (otherwise emtpy) log dir gets packaged
    s.files = files.to_a
  end

  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end

  task :gemspec do
    File.open('radiant.gemspec', 'w') {|f| f.write spec.to_ruby }
  end

  namespace :gem do
    desc "Uninstall Gem"
    task :uninstall do
      sh "gem uninstall #{PKG_NAME}" rescue nil
    end

    desc "Build and install Gem from source"
    task :install => [:package, :uninstall] do
      chdir("#{RADIANT_ROOT}/pkg") do
        latest = Dir["#{PKG_NAME}-*.gem"].last
        sh "gem install #{latest}"
      end
    end
  end

  desc "Publish the release files to RubyForge."
  task :release => [:gem, :package] do
    files = ["gem", "tgz", "zip"].map { |ext| "pkg/#{PKG_FILE_NAME}.#{ext}" }
    release_id = nil
    system %{rubyforge login}
    files.each_with_index do |file, idx|
      if idx == 0
        cmd = %Q[rubyforge add_release #{RELEASE_NOTES}#{RELEASE_CHANGES} --preformatted #{RUBY_FORGE_GROUPID} #{RUBY_FORGE_PACKAGEID} "#{RELEASE_NAME}" #{file}]
        puts cmd
        system cmd
      else
        release_id ||= begin
          puts "rubyforge config #{RUBY_FORGE_PROJECT}"
          system "rubyforge config #{RUBY_FORGE_PROJECT}"
          `cat ~/.rubyforge/auto-config.yml | grep "#{RELEASE_NAME}"`.strip.split(/:/).last.strip
        end
        cmd = %Q[rubyforge add_file #{RUBY_FORGE_GROUPID} #{RUBY_FORGE_PACKAGEID} #{release_id} #{file}]
        puts cmd
        system cmd
      end
    end
  end
end
