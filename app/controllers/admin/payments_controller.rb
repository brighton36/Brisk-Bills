class Admin::PaymentsController < ApplicationController
  include AdminLayoutHelper
  include ExtensibleObjectHelper
  include ApplicationHelper # We need h_money below...

  VALID_INVOICE_ASSIGNMENT_INPUT = /^invoice_assignments_([\d]+)_amount$/
  VALID_MONEY_INPUT = /^(?:[ ]*([\d]+\.[\d]{0,2}|[\d]+)[ ]*|)$/

  class ObservedInvalidAmount < StandardError; end

  active_scaffold :payment do |config|
    config.label = "Payments"

    config.columns = [
      :id,
      :paid_on, 
      :client, 
      :payment_method, 
      :payment_method_identifier, 
      :amount, 
      # Unfortunately, if I actually tried to make the name of this column "invoice_assignments"
      # active_scaffold would try to interpret the post on its own and get in my way:
      :assignments,
      :amount_unallocated, 
      :created_at, 
      :updated_at,
      :is_allocated?
    ]
    
    config.show.columns = [
      :id,
      :paid_on, 
      :client, 
      :payment_method, 
      :payment_method_identifier, 
      :amount, 
      :invoice_assignments,
      :amount_unallocated, 
      :is_allocated?,
      :created_at, 
      :updated_at
    ]

    config.columns[:id].label = 'Num'

    config.columns[:client].form_ui = :select
    config.columns[:client].sort_by :sql => 'clients.company_name'
    
    config.columns[:is_allocated?].label = "Alloc?"
    config.columns[:is_allocated?].includes = [:invoice_assignments]
    
    config.columns[:payment_method_identifier].label = "Identifier"
    
    config.columns[:payment_method].label = 'Method'
    config.columns[:payment_method].form_ui = :select
    config.columns[:payment_method].sort_by :sql => 'payment_methods.name'
    
    config.columns[:amount_unallocated].label = 'Unallocated'
    config.columns[:assignments].label = 'Applies To'
    
    config.columns[:amount].sort_by :sql => 'amount_in_cents'
    
    config.list.columns =[:id, :client, :payment_method,:payment_method_identifier, :amount,:is_allocated?, :paid_on]
    config.list.sorting = [{:paid_on => :desc}]

    config.create.columns = config.update.columns = [
      :paid_on, 
      :client, 
      :amount,
      :payment_method, 
      :payment_method_identifier,
      :amount_unallocated, 
      :assignments
    ]

    observe_active_scaffold_form_fields :fields => %w(client amount), :action => :on_assignment_observation
  end

  # In here we update all the invoice assignments
  def before_update_save(payment)
    # Let's create a lookup map from the input params to make this easier:
    input_assignments = {}
    params[:record][:invoice_assignments].try(:each_pair) do |inv_id, fields|
      input_assignments[inv_id.to_i] = Money.new(fields[:amount].tr('^\-0-9','').to_i)
    end

    assignment_deletes = []
    # First we iterate through the existing relationships:
    payment.invoice_assignments.each do |asgn|
      # Did the assignment get changed by the input? If so...
      if (
        input_assignments.has_key?(asgn.invoice_id) && 
        input_assignments[asgn.invoice_id] != asgn.amount
      )
        # They set this asignment to zero - which means we remove the assignment:
        if input_assignments[asgn.invoice_id] == Money.new(0)
          # Mark this assignment for deletion below
          assignment_deletes << asgn
        else # assign the new value:
          asgn.amount = input_assignments[asgn.invoice_id]
        end
      end
    end
  
    # THis is a little more efficient than deleting in the loop above. Also,
    # I think there's a bug whereby the iterator stops running as soon as you delete somethign in the 
    # assignment collection. This causes subsequent assignments not to run..
    payment.invoice_assignments.delete *assignment_deletes
    
    # And then we go through the open invoices to find if new assignments need to be created:
    payment.client.unpaid_invoices.each do |inv|
      # We need to add a new assignment if there's a non-zero value
      payment.invoice_assignments.build(
          :invoice_id => inv.id, 
          :amount => input_assignments[inv.id]
        ) if (
        # We want to make sure we're not creating an assignment that already exists
        !payment.invoice_assignments.any?{|asgn| asgn.invoice_id == inv.id} &&
        input_assignments.has_key?(inv.id) &&
        input_assignments[inv.id] != Money.new(0)
      )
    end
  end

  alias before_create_save before_update_save

  def on_assignment_observation
    @observed_column = params[:observed_column]

    # First let's load the record in question (or create one) ...
    @record = (/^[\d]+$/.match(params[:record_id])) ? 
      Payment.find(params[:record_id].to_i) : Payment.new

    # We'll need these later in the helper/rjs...
    params[:id] = params[:record_id] # This is a hack to make the options_for_column work as expected
    define_scaffold_observations

    # We don't have to raise on this one really. Its not consequential if this is screwy
    @record.client_id = params[:client].to_i if /^[\d]+$/.match params[:client]

    # Let's make sure all the amounts we've been given are acceptable:
    @invalid_amount_columns = params.to_enum(:each_pair).collect{|key,value| 
      key if (VALID_INVOICE_ASSIGNMENT_INPUT.match key or key == 'amount') and !VALID_MONEY_INPUT.match value
    }.compact

    if @invalid_amount_columns.length > 0
      # We'll end up needing this when we're clearing out amounts outstanding due to a mis-type
      @invoice_map = Invoice.find(
        :all,
        :conditions => ['id IN (?)', @invalid_amount_columns.collect{|colname| $1 if VALID_INVOICE_ASSIGNMENT_INPUT.match colname}]
      ).inject({}){|ret, inv| ret.merge({inv.id => inv})}
      
      raise ObservedInvalidAmount
    end

    # This is an important field to get right. Remember that we already validating this param above:
    @record.amount = Money.new(params[:amount].to_f*100) if params.has_key? :amount

    case @observed_column
      when /^(?:amount|client)$/
        # Let's try to guess the right assignments automatically:
        @record.invoice_assignments = @record.client.recommend_invoice_assignments_for(
          @record.amount
        ) if @record.client and @record.amount

      when VALID_INVOICE_ASSIGNMENT_INPUT
        @observed_invoice = Invoice.find $1.to_i

        update_assignments_from_params @record

        @observed_assignment = @record.invoice_assignments.to_a.find{|ia| ia.invoice_id == @observed_invoice.id}
    end

    rescue ObservedInvalidAmount
      render :action => :observation_error
  end

  private

  def update_assignments_from_params(record)
    # First we build a lookup with all ids that were passed in the params, 
    # and which have an assignment amount greater than 0
    assignments = {}
    
    params.each_pair do |key,value|
      if VALID_INVOICE_ASSIGNMENT_INPUT.match key
        inv_id = $1.to_i
        assignments[inv_id] = Money.new(params[key].to_f*100) 
      end
    end

    # Now go ahead and delete the invoice_assignments that no longer have money attributed to them
    record.invoice_assignments.each do |ia|
      record.invoice_assignments.delete ia unless assignments.keys.include? ia.invoice_id
    end
  
    # And lastly, add new the assignments and/or update existing assignments in the record:
    assignments.each_pair do |inv_id,amount|
      ia = record.invoice_assignments.to_a.find{|ia| ia.invoice_id == inv_id}
      ia ||= record.invoice_assignments.build :invoice_id => inv_id
      
      ia.amount = amount
    end
    
    record
  end

  handle_extensions
end
