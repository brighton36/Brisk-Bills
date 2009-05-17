# Very simple plugin that we end up using to manage column ordering a bit on our crazier active scaffolds

module AsMoveColumnsUnder
  def move_column_under(col_targ,col_under)
    if @set.include? col_under
      @set.delete col_targ.to_sym
      @set.insert( (col_under.nil?) ? 0 : (@set.index(col_under)+1), col_targ )
    end
  end
end

# NOTE: Really, we want to extend ActiveScaffold::DataStructures::ActionColumns, however, for reasons I don't understand,
#       if we try to make the slightest adjustment to this class, we end up with weirdo errors. So, sending this to 
#       ActiveScaffold::Configurable does the same thing. (Though this is sloppy b/c a lot of stuff that doesnt need this
#       is getting sent this...

ActiveScaffold::Configurable.send :include, AsMoveColumnsUnder