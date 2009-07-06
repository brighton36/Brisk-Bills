## Redefined standard Rails tasks only in instance mode. Kind of a ridiculous hack, but - I grabbed it from radiant, and it works...
unless BriskBills.app?
  require 'rake/testtask'

  railties_tasks_dir = [
      "#{RAILS_ROOT}/vendor/rails/lib/tasks",
      "#{BRISKBILLS_ROOT}/vendor/rails/lib/tasks", 
      "#{RAILTIES_PATH}/lib/tasks"
    ].find{|d| File.directory? d}
  
  Dir[railties_tasks_dir+'/*.rake'].each do |rake|
    lines = IO.readlines(rake)
    lines.map! do |line|
      line.gsub!('RAILS_ROOT', 'BRISKBILLS_ROOT') unless rake =~ /(misc|rspec|databases)\.rake$/
      case rake
      when /testing\.rake$/
        line.gsub!(/t.libs << (["'])/, 't.libs << \1#{BRISKBILLS_ROOT}/')
        line.gsub!(/t\.pattern = (["'])/, 't.pattern = \1#{BRISKBILLS_ROOT}/')
      when /databases\.rake$/
        line.gsub!(/(migrate|rollback)\((["'])/, '\1(\2#{BRISKBILLS_ROOT}/')
        line.gsub!(/(run|new)\((:up|:down), (["'])db/, '\1(\2, \3#{BRISKBILLS_ROOT}/db')
      end
      line
    end
    eval(lines.join("\n"), binding, rake)
  end
end