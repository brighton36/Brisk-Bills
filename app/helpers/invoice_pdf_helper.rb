module InvoicePdfHelper #:nodoc:
  
  
end

# This let's us add the on_start_new_page functionality in the PDF::Writer library

class SerializableProc #:nodoc:
   def self._load( proc_string )
   new(proc_string)
   end

   def initialize( proc_string )
   @code = proc_string
   @proc = nil
   end

   def _dump( depth )
   @code
   end

   def method_missing( method, *args )
   if to_proc.respond_to? method
   @proc.send(method, *args)
   else
   super
   end
   end

   def to_proc( )
   return @proc unless @proc.nil?

   if @code =~ /\A\s*(?:lambda|proc)(?:\s*\{|\s+do).*(?:\}|end)\s*\Z/
   @proc = eval @code
   elsif @code =~ /\A\s*(?:\{|do).*(?:\}|end)\s*\Z/
   @proc = eval "lambda #{@code}"
   else
   @proc = eval "lambda { #{@code} }"
   end
   end

   def to_yaml( )
   @proc = nil
   super
   end
end

module PDF #:nodoc:
  class Writer #:nodoc:
    unless method_defined? :start_new_page_without_callback
      def on_start_new_page(run_now , serializable_exec)
        @on_start_new_page = serializable_exec
        @on_start_new_page.to_proc.call self if run_now
      end
  
      alias start_new_page_without_callback start_new_page
  
      def start_new_page(*args)
        new_page_proc = @on_start_new_page.to_proc unless @on_start_new_page.nil? or !@on_start_new_page.respond_to?(:to_proc)
  
        # This first one is a little ghetto... would be nice if it were actually called on the first page
        #new_page_proc.call self if current_page_number == 1 and new_page_proc
        ret = start_new_page_without_callback(*args)
  
        new_page_proc.call self if new_page_proc
  
        ret
      end
    end
  end
end