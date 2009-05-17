module ActivityTypeModelHelper 
  
  def self.append_features(base)
    super
    
    base.class_eval do
      belongs_to :activity, :class_name => "::Activity"
      belongs_to :client, :class_name => "::Client"
      
      hack_an_association_join(:client) do |association|
        " LEFT OUTER JOIN %s ON %s.%s = %s.%s " % [
          association.klass.table_name, 
          association.aliased_table_name, 
          association.reflection.klass.primary_key,
          'activities', 
          association.klass.to_s.foreign_key
        ]
      end
      
      # Client hacks
      def []=(field,value)
        return activity.nil? ? nil : ( activity[:client_id] = value ) if field.to_sym == :client_id
        
        super field, value
      end
      
      def [](field)
        return activity.nil? ? nil : activity[:client_id] if field.to_sym == :client_id
    
        super field
      end
      
      def client=(value)
        build_activity if activity.nil? and value
        activity.client = value
      end
    
      class << self
        def client_arrange_include_param(args)
          # THis forces the :activity to always occur before :client in an :include
          args.each do |arg|
            if (
              arg.respond_to? :has_key? and
              arg.has_key? :include and
              arg[:include].respond_to? :include? and
              arg[:include].include? :client
            )
              arg[:include] = ([:activity] + arg[:include]).uniq
            end
          end
        end
        
        def find(*args)
          client_arrange_include_param args
          super(*args)
        end
    
        def count(*args)
          client_arrange_include_param args
          super(*args)
        end
      end
      # /Client Hacks
      
      # We use this when printing invoices, probably not the best way to do this, but its fine enough for now
      def as_legacy_ledger_row
        begin
          # We just do this to help when writing your activity types, as a starting point
          if label and comments and label.length > 0 and comments.length > 0
            description = '%s - %s' % [label, comments]
          else
            description = (label and label.length > 0) ? label : comments
          end
        rescue
          description = 'TODO: Lorem ipsum dolor sit amet, consectetuer adipiscing elit. '
        end
        
        [
         1,
         activity.cost,
         activity.cost,
         activity.activity_type.capitalize,
         occurred_on.strftime('%m/%d/%y'),
         description
        ]
      end

      # Generally useful accessors & utils for the activity association
      
      def column_for_attribute(name)
        # My hack to support the execute_callstack_for_multiparameter_attributes() set for occurred_on
        (name.to_sym == :occurred_on) ? OpenStruct.new( :klass => Time ) : super(name)
      end
      
      def is_published
        activity.is_published if activity
      end
      
      def occurred_on
        self.activity.occurred_on if activity
      end
      
      def cost
        self.activity.cost if activity
      end
      
      def tax
        self.activity.tax if activity
      end
      
      def type_quick_namer(*args)
        nil_label = '(None)'
        
        namer_format = args.shift
        
        args.map! do |a|   
          if a.nil?
            nil_label
          elsif a.respond_to? :name
            a.name
          else
            a.to_s
          end
        end
        
        args << ((activity.nil?) ? nil_label : activity.occurred_on.strftime("%m/%d/%Y %I:%M %p"))
        
        namer_format % args
      end
      
      # Activity hacks:
      alias build_activity_without_type_helper build_activity
      
      def build_activity(record = {})
        if /^[^\:]+\:\:(.+)$/.match(self.class.to_s)
          record[:activity_type] = $1.downcase
        end
        
        build_activity_without_type_helper record
      end
      
      # Published handling:
      def is_paid?
        (activity.nil?) ? false : activity.is_paid?
      end
      
      def is_published?
        (activity.nil?) ? false : activity.is_published?
      end
      
      before_destroy :ensure_not_published
        
      def ensure_not_published
        if is_published?
          errors.add_to_base "Can't destroy an activity once its invoice is published"
          return false
        end
      end
      
      def validate_on_update
        errors.add_to_base "Activity can't be adjusted once its invoice is published" if is_published? and changed_attributes.length > 0 
      end
      # /No updates/destroys
      
      # Event handlers:
      alias initialize_without_activity_type_helper initialize
      def initialize(*args)
        initialize_without_activity_type_helper(*args)
        build_activity if new_record? and activity.nil?
      end
  
      after_destroy { |record| record.activity.destroy }
      
      before_save { |record| record.activity.save if record.activity and record.activity.changed? }
      
      attr :dont_validate_activity_association
      def validate
        super
        
        unless dont_validate_activity_association
          if activity.nil?
            errors.add :activity, 'missing'
          else
            activity.dont_validate_type_associations = true
            activity.valid?
            activity.errors.each { |attr, msg| errors.add attr, msg }
          end
        end
      end
      
    end
  end

end