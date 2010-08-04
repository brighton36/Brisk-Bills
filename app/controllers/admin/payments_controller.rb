class Admin::PaymentsController < ApplicationController
  include AdminLayoutHelper
  include ExtensibleObjectHelper
  include ApplicationHelper # We need h_money below...

  active_scaffold :payment do |config|
    config.label = "Payments"

    config.columns = [:paid_on, :client, :payment_method, :payment_method_identifier, :amount, :invoice_assignment, :unallocated_amount, :created_at, :updated_at]

    config.columns[:client].form_ui = :select
    config.columns[:client].sort_by :sql => 'clients.company_name'
    
    config.columns[:payment_method].form_ui = :select
    config.columns[:payment_method].sort_by :sql => 'payment_methods.name'
    
    config.columns[:payment_method_identifier].description = 'Last four card digits, check number...'
    config.columns[:payment_method_identifier].label = 'Method Identifier'

    config.columns[:unallocated_amount].label = 'Unallocated'
    config.columns[:invoice_assignment].label = 'Posted To'
    
    config.columns[:amount].sort_by :sql => 'amount_in_cents'
    
    config.list.columns =[:client, :payment_method, :amount, :paid_on]
    config.list.sorting = [{:paid_on => :desc}]

    config.create.columns = config.update.columns = [
      :paid_on, 
      :client, 
      :payment_method, 
      :payment_method_identifier, 
      :amount, 
#      :unallocated_amount, 
#      :invoice_assignment
    ]
    
    config.update.link = nil
    
#    observe_active_scaffold_form_fields :fields => %w(client amount), :action => :on_invoice_assignment_observation
  end

  def before_update_save(payment)      
    payment.invoice_assignments = payment.client.recommend_invoice_assignments_for payment.amount
  end

  alias before_create_save before_update_save


  def on_invoice_assignment_observation
    record_id = (/^[\d]+$/.match(params[:record_id])) ? params[:record_id].to_i : nil
    
    # TODO: if amount is no integer - highlight...
    
    render(:update) do |page|
      
      #TODO: We need to load the pre-existing payment here...
      
      # Let's do some (minimal) Amount input handling
      unless params[:amount].empty?
        begin
          record_amount_js_id = "record_amount_#{record_id}"
          
          new_amount = Money.new($1.to_f*100) if /^[ ]*([\d]+\.[\d]{0,2}|[\d]+)[ ]*$/.match params[:amount]
          
          raise StandardError unless new_amount
          
          page[record_amount_js_id].value = new_amount.to_s
          page.replace_html "record_unallocated_amount_#{record_id}", :text => h_money(new_amount)
        rescue
          page[record_amount_js_id].value = ''
          page[record_amount_js_id].focus
          page.visual_effect :highlight, record_amount_js_id, :duration => 3, :startcolor => "#FF0000"
        end
      end
      
      # TODO: Generate the invoices div...
    end
  end

  handle_extensions
end
