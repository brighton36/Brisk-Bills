require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

require 'fileutils'
require 'tempfile'

require "#{RAILS_ROOT}/lib/brisk-bills.rb"

include FileUtils


namespace :package do
  desc "Packaging Tasks" 
  
  RbConfig = Config unless defined? RbConfig
  
  NAME = "brisk-bills"
  VERS = ENV['VERSION'] || BriskBills::Version.to_s
  PKG = "#{NAME}-#{VERS}"
  
  RDOC_OPTS = ['--quiet', '--title', 'The BriskBills Programmers Reference', '--main', 'README', '--inline-source']
  RDOC_FILES = ['README', 'INSTALL', "CHANGELOG", "COPYING","COPYING.LESSER", 'bin/brisk-bills']
  PKG_FILES = (%w(Rakefile) + RDOC_FILES + Dir.glob("{app,bin,config,db,doc,lib,log,public,Rakefile,script,test,tmp,vendor}/**/*")).uniq

  SPEC =
    Gem::Specification.new do |s|
      s.name = NAME
      s.version = VERS
      s.platform = Gem::Platform::RUBY
      s.has_rdoc = true
      s.bindir = 'bin'
      s.executables = 'brisk-bills'
      s.rdoc_options += RDOC_OPTS
      s.extra_rdoc_files = RDOC_FILES
      s.summary = "A full-featured, rails-based system for basic accounting, with a particular focus on invoicing and automatic bill generation."
      s.description = s.summary
      s.author = "Chris DeRose, DeRose Technologies, Inc."
      s.email = 'cderose@derosetechnologies.com'
      s.homepage = 'http://www.derosetechnologies.com/community/brisk-bills'
      s.rubyforge_project = 'brisk-bills'
      s.files = PKG_FILES
      s.require_paths = ["lib"] 
      s.test_files = FileList['test/*']
      
      s.add_dependency 'extensions'
      s.add_dependency 'pdf-writer'
      s.add_dependency 'slimtimer4r'
    end
  
  Rake::RDocTask.new do |rdoc|
      rdoc.rdoc_dir = 'doc/rdoc'
      rdoc.options += RDOC_OPTS
      rdoc.main = "README"
      rdoc.rdoc_files.add RDOC_FILES+['lib/**/*.rb']
  end
  
  Rake::GemPackageTask.new(SPEC) do |p|
      p.need_tar = true
      p.need_zip = true
      p.gem_spec = SPEC
  end
  
  task :install do
    sh %{rake package}
    sh %{sudo gem install pkg/#{NAME}-#{VERS}}
  end
  
  task :uninstall => [:clean] do
    sh %{sudo gem uninstall #{NAME}}
  end
end