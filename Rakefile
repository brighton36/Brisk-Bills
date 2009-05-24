require File.join(File.dirname(__FILE__), 'config', 'boot')

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

unless Rake::Task.task_defined? "package:release"
  Dir["#{BRISKBILLS_ROOT}/lib/tasks/**/*.rake"].sort.each { |ext| load ext }
end