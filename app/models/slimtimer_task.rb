class SlimtimerTask < ActiveRecord::Base  
  
  def label
    name unless name.nil?
  end
end
