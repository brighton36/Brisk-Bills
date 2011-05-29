module Admin::ActivityTypeControllerHelper
  
  def self.append_features(base)
    super

    base.class_eval do
      
      def self.add_activity_type_config(config, options = {})
        
        options[:except_columns] ||= []
        
        unless options[:except_columns].include? :cost
          config.columns << :cost
          config.columns[:cost].sort_by :sql => "activities.cost"
        end

        unless options[:except_columns].include? :apply_tax
          config.columns << :apply_tax
        end

        unless options[:except_columns].include? :tax
          config.columns << :tax
          config.columns[:tax].sort_by :sql => "activities.tax"
        end

        unless options[:except_columns].include? :is_published
          config.columns << :is_published
          config.columns[:is_published].includes = [:activity]
          config.columns[:is_published].form_ui = :checkbox
        end
        
        unless options[:except_columns].include? :occurred_on
          config.columns << :occurred_on
          config.columns[:occurred_on].includes = [:activity]
          config.columns[:occurred_on].sort_by :sql => "activities.occurred_on"
          
          config.list.sorting = [{:occurred_on => :desc}]
        end
        
        unless options[:except_columns].include? :client
          config.columns << :client
          config.columns[:client].sort_by :sql => "clients.company_name"
          config.columns[:client].form_ui = :select
        end

        crud_columns = [:occurred_on, :client,:cost, :apply_tax, :tax].reject{|c| true if options[:except_columns].include? c}
    
        [config.update, config.create].each do |crud_config|
          crud_config.columns = []  
          crud_config.columns.add_subgroup('Activity'){ |g| g.add crud_columns }
        end

      end
    
      def update_record_from_params(parent_record, columns, attributes)
        activity_params = HashWithIndifferentAccess.new
        record_params = HashWithIndifferentAccess.new

        attributes.delete 'apply_tax'

        attributes.each_pair { |k,v| ((/^(occurred_on|is_published|cost|tax)/.match k) ? activity_params : record_params )[k] = v }
        
        parent_record = super(parent_record, columns, record_params)
        parent_record.activity.attributes = activity_params if activity_params.length > 0
        
        parent_record
      end
      
      def conditions_for_collection
        # NOTE: We may want to remove this method?
        # Depends on if/how we end up as a subform in the invoices list ...
        ['activities.is_published = ?', 1]
      end
    
      def before_create_save(record)
        record.activity.is_published = true if params[:action] == 'create'
      end
      
      # override_form_field_partial in the helper gets buggered out b/c our controller name doesn't match
      # the model name. This fixes that:
      def self.active_scaffold_controller_for(klass)
        self
      end
      
    end
    
  end
  
end