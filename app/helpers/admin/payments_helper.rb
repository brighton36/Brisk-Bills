module Admin::PaymentsHelper
  include Admin::IsActiveColumnHelper
  
  def amount_column(record)
    h_money record.amount
  end
  
  def client_form_column(record, input_name)
    (record.new_record?) ?
      select_tag(
        "record[client][id]", 
        options_for_select(
          [["- select -", nil]]+Client.find(:all, :order => 'company_name ASC').collect{|c| [c.company_name, c.id] },
          record.client_id
        ), 
        options_for_column('client')
      ) :
      span_field(h(record.client.company_name))
  end
  
  def paid_on_form_column(record, input_name)
    (record.new_record?) ?
      input(:record, :paid_on, options_for_column('paid_on')) :
      span_field(h(record.paid_on.strftime('%m/%d/%y %I:%M %p')))
  end

  def amount_form_column(record, input_name)
    (record.new_record?) ?
      text_field_tag(
        input_name, 
        record.amount, 
        options_for_column('amount').merge( {:size => 8, :class=>'text-input' } )
      ) :
      span_field(h_money(record.amount)) 
  end

  def payment_method_form_column(record, input_name)
    (record.new_record?) ?
      select_tag(
        "record[payment_method][id]", 
        options_for_select(
          [["- select -", nil]]+PaymentMethod.find(:all, :order => 'name ASC').collect{|pm| [pm.name, pm.id] },
          record.payment_method_id
        ), 
        options_for_column('payment_method')
      ) :
      span_field(h(record.payment_method.name))
  end

  def payment_method_identifier_form_column(record, input_name)
    (record.new_record?) ?
      text_field_tag(
        input_name, 
        record.payment_method_identifier, 
        options_for_column('payment_method_identifier').merge( {:size => 30, :class=>'text-input' } )
      )+span_field(t(:payment_method_identifier_description), :class => "description") :
      span_field(h(record.payment_method_identifier)) 
  end

  def amount_unallocated_form_column(record, input_name)
    span_field(
      (record.amount) ? h_money(record.amount_unallocated) : t(:enter_a_payment_amount),
      :id => ('record_amount_unallocated_%s' % record.id)
    )
  end
  
  def assignments_column(record)
    record.invoice_assignments.collect{|ia| 
      '%s to Invoice %d' % [ia.amount.format, ia.invoice.id   ]
    }.join ', '
  end
  
  def invoice_assignments_column(record)
    record.invoice_assignments.collect{ |asgn|
      '%s to (Invoice %d)' % [asgn.amount.format, asgn.invoice_id  ]
    }.join ', '
  end
  
  def assignments_form_column(record, input_name = nil)
    content_tag(:div, :id => 'record_invoice_assignment_%s' % record.id ) do
      if record.client
        
        # First, we show the easy, upaid invoices. These should always be visible:
        show_invoices = record.client.unpaid_invoices.to_a
        
        # Now - we add any additional invoices that might be around from existing assignments (the case for an edit...)
        record.invoice_assignments.each do |inv_asgn|
          show_invoices << inv_asgn.invoice unless show_invoices.find{|show_inv| show_inv.id == inv_asgn.invoice_id}
        end

        # And now let's sort everything by the id
        show_invoices = show_invoices.sort!{|a,b| a.id <=> b.id }
          
        if show_invoices.length > 0
          
          assignment_observation = @active_scaffold_observations.find{|o| o[:action] == :on_assignment_observation}.dup
          
          assignment_observation[:fields] += show_invoices.collect{ |inv|
            'invoice_assignments_%d_amount' % inv.id
          }

          # This is a look-up map that will tell us the field values to use below:
          inv_assignments = record.invoice_assignments.inject({}){|ret,ia| ret.merge({ia.invoice_id => ia.amount}) }

          content_tag(:ul, :class => 'invoice_assignment_inputs') do
            show_invoices.collect{|inv|
              col_name = 'invoice_assignments_%d_amount' % inv.id
              
              assignment_amount = nil
              assignment_amount = (inv_assignments.has_key? inv.id) ? inv_assignments[inv.id] : '0.00' if record.amount

              '<li>%s%s %s</li>' % [
                text_field_tag( 
                    'record[invoice_assignments][%d][amount]' % inv.id, 
                    assignment_amount, 
                    :size  => 8, 
                    :class => 'text-input',
                    :id    => options_for_column(col_name)[:id]
                ),
                active_scaffold_observe_field(col_name,assignment_observation),
                t(
                  :invoice_outstanding_details,
                  :inv_id => inv.id, 
                  :issued_on => h(inv.issued_on.strftime('%m/%d/%y')),
                  :amount_outstanding => span_field(
                    h_money(invoice_amount_outstanding_for(inv, record.id,inv_assignments[inv.id])),
                    :id => ('%s_outstanding' % options_for_column(col_name)[:id])
                  )
                )
              ]
            }.join
          end
        else
          span_field t(:no_outstanding_invoices_for_account)
        end
      else
        span_field t(:choose_a_client)
      end  
    end

  end

  # This keeps our rjs files a little DRY-er
  def amount_field_id
    "record_amount_%s" % @record.id
  end

  # This keeps our rjs files a little DRY-er
  def amount_unallocated_field_id
    "record_amount_unallocated_%s" % @record.id  
  end
  
  # All this craziness exists to show a modal dialog asking the user to confirm any payment that isn't fully allocated.
  def submit_tag(*args)
    if (/\A(?:#{as_(:update)}|#{as_(:create)})\Z/.match args[0])
      action = args[0] == as_(:update) ? :update : :create 
      
      button_to_function( 
        args[0], 
        "amt_unalloc = $$('#record_amount_unallocated_%s span');
        if (amt_unalloc.length > 0 && amt_unalloc.first().innerHTML != '%s') {
          show_modal_after_close(%s,%s);
        } else {
          $('%s').onsubmit();
        }" % [
          @record.id,
          Money.new(0).format,
          render(:file => 'admin/payments/commit_payment_warning.rhtml', :layout => false, :locals => {:action => action}).to_json,
          {:title => 'Are you sure you wish to save?', :width => 600}.to_json,
          element_form_id(:action => action)
        ],
        args[1]
      )
    else
      super(*args)
    end
  end

  private
  
  # This method is a little weird. But, its used in a couple places to determine what the amount oustanding
  # is for an invoice, after the provided payment_id has been removied, and after the provided amount
  # has been applied. Its not as efficient as I'd like. But, it works
  def invoice_amount_outstanding_for(invoice, payment_id, amount = nil)
    invoice.amount-(
      invoice.payment_assignments.to_a.reject{|ip| 
        payment_id == ip.payment_id
      }.inject(Money.new(0)){|ret, ip| 
        ret+ip.amount
      }+(
        (amount) ? amount : Money.new(0)
      )
    )
  end
  
  def span_field(content, options = {})
    content_tag(
      :span, 
      content, 
      {:class => 'active-scaffold_detail_value' }.merge(options)
    )    
  end

  # We write this as an overide on the default behavior. Nothing needs to change in the case that this is a
  # new record. But, if we're editing, a number of our input fields aren't on the page. For this
  # case, we need to not query these for their value
  def active_scaffold_observe_field(col_name, observation) 
    unless @record.new_record?
      # We won't be observing anything if its one of these columns
      return %{} if /\A(?:client|amount)\Z/.match col_name
      
      # Its an amount column. For these, just remove the $F reference to the removed fields
      ["client", "amount"].each{ |f| observation[:fields].delete f}
    end
    
    super col_name, observation
  end
end
