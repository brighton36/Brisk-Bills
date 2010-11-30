module Admin::PaymentsHelper
  include Admin::IsActiveColumnHelper
  
  def amount_column(record)
    h_money record.amount
  end
  
  def client_form_column(record, input_name)
    logger.error "hmmmm: #{self.inspect}"
#TODO:    active_scaffold_input_singular_association
    (record.new_record?) ?
      input(:record, :client, options_for_column('client')) :
      span_field(h(record.client.label))
  end
  
  def paid_on_form_column(record, input_name)
    (record.new_record?) ?
      input(:record, :paid_on, options_for_column('paid_on')) :
      span_field(h(record.paid_on))
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

  def payment_method_identifier_form_column(record, input_name)
    (record.new_record?) ?
      text_field_tag(
        input_name, 
        record.payment_method_identifier, 
        options_for_column('payment_method_identifier').merge( {:size => 30, :class=>'text-input' } )
      ) :
      span_field(h(record.payment_method_identifier)) 
  end

  def amount_unallocated_form_column(record, input_name)
    span_field(
      (record.amount) ? h_money(record.amount_unallocated) : t(:enter_a_payment_amount),
      :id => ('record_amount_unallocated_%s' % record.id)
    )
  end
  
  def invoice_assignments_column(record)
    record.invoice_assignments.collect{|ia| 
      '%s to Invoice %d' % [ia.amount.format, ia.invoice.id   ]
    }.join ', '
  end
  
  def invoice_assignments_form_column(record, input_name = nil)
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
          
          assignment_observation = @active_scaffold_observations.find{|o| o[:action] == :on_invoice_assignment_observation}.dup
          
          assignment_observation[:fields] += show_invoices.collect{ |inv|
            'invoice_assignments_%d_amount' % inv.id
          }

          # This is a look-up map that will tell us the field values to use below:
          inv_assignments = record.invoice_assignments.inject({}){|ret,ia| ret.merge({ia.invoice_id => ia.amount}) }

          content_tag(:ul, :class => 'invoice_assignment_inputs') do
            show_invoices.collect{|inv|
              col_name = 'invoice_assignments_%d_amount' % inv.id

              '<li>%s%s %s</li>' % [
                text_field_tag( 
                    'record[invoice_assignments][%d][amount]' % inv.id, 
                    (record.amount) ? 
                      ((inv_assignments.has_key? inv.id) ? inv_assignments[inv.id] : '0.00' ) : 
                      nil, 
                    :size  => 8, 
                    :class => 'text-input',
                    :id    => options_for_column(col_name)[:id]
                ),
                active_scaffold_observe_field(col_name,assignment_observation),
                t(
                  :invoice_outstanding_details,
                  :inv_id => inv.id, 
                  :issued_on => h(inv.issued_on.strftime('%m/%d/%y')),
                  :amount_outstanding => h_money(inv.amount_outstanding)
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
  
  private
  
  def span_field(content, options = {})
    content_tag(
      :span, 
      content, 
      {:class => 'active-scaffold_detail_value' }.merge(options)
    )    
  end

end
