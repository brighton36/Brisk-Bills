require 'extensions/module'

class DummyActiveScaffoldColumn
  # This exists merely for ActiveScaffold::Helpers::FormColumns::options_for_column
  attr_accessor :name

  def initialize(name)
    @name = name
  end
end

module AsFoFormColumnsFeatures

  def options_for_column(name)
    # NOTE: I've found this to be a useful little utility method in general...
    active_scaffold_input_options DummyActiveScaffoldColumn.new(name)
  end
  
  def active_scaffold_input_for_with_observation(column, scope = nil)
    ret = active_scaffold_input_form_without_observation column, scope
    
    @active_scaffold_observations.each do |observation|
      col_name = column.name.to_s
      
      ret << active_scaffold_observe_field(col_name, observation) if observation[:fields].include? col_name
    end if @active_scaffold_observations

    ret
  end
  
  def active_scaffold_observe_field(col_name, observation)
    observe_url = url_for(:action => observation[:action])
    
    observe_cols = observation[:fields]
    options = options_for_column col_name
    
    observe_with = "'record_id=%s&observed_column=%s" % [ @record.id, col_name ]
    observe_with << "&eid=%s" % params[:eid] if params.has_key? :eid

    observe_cols.each_index do |i|
      c = observe_cols[i]
      c_id = options_for_column(c)[:id]
      
      observe_with << "&%s='+$F('%s')%s" % [c, c_id, ((i+1 == observe_cols.length) ? '' : "+'" ) ]
    end

    observe_field options[:id], :url => observe_url, :with => observe_with
  end

  def self.append_features(base)
    super
    base.class_eval do 
      
      unless method_defined? :active_scaffold_input_form_without_observation
        alias active_scaffold_input_form_without_observation active_scaffold_input_for
        alias active_scaffold_input_for active_scaffold_input_for_with_observation
      end
      
    end
  end

end

module AsFoActionControllerFeatures
  def self.append_features(base)
    super
    base.class_eval do 
      extend ClassMethods 
      
      before_filter :define_scaffold_observations, :only => [ :update, :edit, :new, :create ] 
    end
  end

  def define_scaffold_observations
    @active_scaffold_observations = self.class.active_scaffold_observations
  end
  
  module ClassMethods

    attr_accessor :active_scaffold_observations
    
    def observe_active_scaffold_form_fields(options = {}, &block)
      @active_scaffold_observations ||= []

      options[:fields] ||= []

      if block
        # We should come up with a better name then :active_scaffold_observation_block, something unique so that we can have multiple procs in there...
        action_name = ('scaffold_observation_%d' % [@active_scaffold_observations.length+1]).to_sym
        self.send :define_method, action_name, &block
        options[:action] = action_name
      elsif options[:action].nil?
        raise StandardError
      end

      @active_scaffold_observations << options
    end
  end
end