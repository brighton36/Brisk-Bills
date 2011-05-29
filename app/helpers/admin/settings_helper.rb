module Admin::SettingsHelper
  
  %w(description keyname label).each do |col|
    define_method('setting_%s_form_column' % col) { |record, input_name| h record.send(col) }
  end
  
  
end
