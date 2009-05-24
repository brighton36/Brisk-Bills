# This just helps in a couple places, and I'm putting it here.
class String
  def to_re
    source, options = ( /^\/(.*)\/([^\/]*)$/.match(self) )? [$1, $2] : [self,nil]
    
    mods = 0
    
    options.each_char do |c| 
      mods |= case c
        when 'i': Regexp::IGNORECASE
        when 'x': Regexp::EXTENDED
        when 'm': Regexp::MULTILINE
      end
    end unless options.nil? or options.empty?
        
    Regexp.new source, mods
  end
end