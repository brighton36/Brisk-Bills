class Admin::ActivitiesController < ApplicationController
  include AdminLayoutHelper
  include ExtensibleObjectHelper
 
  def self.activities_scaffold_config(&block)
    @activities_scaffold_configs ||= []
    @activities_scaffold_configs << block.to_proc  
  end
  
  def self.activities_scaffold_init
    # I dont love this mechanism of scaffold_init - but I think its going to work quite well...
    configs = @activities_scaffold_configs

    active_scaffold(:activity){|c| configs.each{|ac| ac.call c if ac.respond_to? :call} }
  end
  
  activities_scaffold_config do |config|
    config.label = "Activity Quick-Review"
    
    config.show.link = nil
    config.search.link = nil
    config.create.link = nil
    
    config.list.per_page = 6
    
    config.list.sorting = { :occurred_on => :asc }
    
    config.columns = [:activity,:invoice, :occurred_on]
    
    config.columns[:occurred_on].form_ui = :calendar
    
    config.list.columns = [:activity, :occurred_on]
    
    config.create.columns = config.update.columns =  [:occurred_on]
# TODO    
#    config.full_list_refresh_on = [:update, :create, :destroy]
    
    # This allows us to use the for_activity_type parameter to selectively constriain fields to the appropriate record types.
    config.columns.instance_eval do    

      # Column selective inclusion, based on activity_type:
      alias :add_without_activities :add
      
      def extend_activity_column(col)     
        def col.for_activity_type?(type); (for_activities.length == 0 or for_activities.include? type) ? true : false; end
        def col.for_activities; @for_activities ||= []; end
      end
      
      # Extend the existing columns:
      @set.each{|col| extend_activity_column col}
      
      # And ensure that we continue to do the same for new ones here on:
      def add(*args)
        add_without_activities *args
  
        args.flatten.collect { |a| extend_activity_column find_by_name(a.to_sym) }
      end
      
      alias :<< :add
    end

  end

  private
  
  def do_activity_type_for_method?(method_name)
    self.respond_to? "#{@record.activity_type}_#{method_name}".to_sym
  end
  
  def do_activity_type_for_method(*args)
    method_name = args.shift
    
    unless @record.nil?
      activity_action = "#{@record.activity_type}_#{method_name}".to_sym
      self.send( *([activity_action] + args) ) if self.respond_to? activity_action
    end
  end

  def conditions_for_collection
    ['activities.is_published = ?', 0] if params[:parent_model].nil?
  end
  
  def list_row_class(record)
    record.activity_type
  end

  def do_edit
    super
    do_activity_type_for_method :do_edit
  end

  def do_update
    super
    do_activity_type_for_method :do_update
  end
    
  def before_update_save(record)
    super(record)
    record.is_published = true
    
    do_activity_type_for_method :before_update_save, record
  end

  def update_record_from_params(activity_record, columns, attributes)
    activity_params = HashWithIndifferentAccess.new
    subactivity_params = HashWithIndifferentAccess.new
    
    attributes.delete 'apply_tax'
    
    attributes.each_pair { |k,v| ((/^(occurred_on|is_published|cost|tax|client_id)/.match k) ? activity_params : subactivity_params )[k] = v }

    activity_record = super(activity_record, columns, activity_params)
    activity_record.sub_activity.attributes = subactivity_params if subactivity_params.length > 0        
    
    activity_record
  end
  
  def do_list 
    super

    records_by_type = {}

    @records.each do |r|
      records_by_type[r.activity_type] ||= []
      records_by_type[r.activity_type] << r
    end

    records_by_type.each_pair do |activity_type, records|
      do_list_action = "#{activity_type}_do_list".to_sym

       self.send( do_list_action, records) if self.respond_to? do_list_action
    end
  end
  
  public
  
  def row        
    # I think they should have had a do_row in active scaffold ....
    record = find_if_allowed(params[:id], :read)
    
    do_list_action = "#{record.activity_type}_do_list".to_sym

    self.send( do_list_action, [record]) if self.respond_to? do_list_action
    
    render :partial => 'list_record', :locals => {:record => record}
  end

  handle_extensions

  activities_scaffold_init
end
