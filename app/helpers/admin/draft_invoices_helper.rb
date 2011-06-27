module Admin::DraftInvoicesHelper
  # This isn't actually used by active scaffold, hence our non-standard argument list
  def batch_create_clients_form_column(invoice_date_at, checked_client_ids = nil)
    clients = Client.find_invoiceable_clients_at invoice_date_at


    (clients.length > 0) ?
      '<div id="batch_invoice_clients_list">%s</div>' % clients.in_groups_of((clients.length.to_f/3).ceil, false).collect{ |group|
        '<ul class="checkbox-list">%s</ul>' % group.collect{ |client|
            list_i = (list_i) ? list_i+1 : 0
            chk_name = "%s[%d][id]" % ['batch_client', client.id]
            chk_id = "%s_client_%d" % ['batch_client', client.id]

            '<li>%s<label for="%s">%s</label></li>' % [ 
              check_box_tag(chk_name, client.id, (checked_client_ids.nil? || checked_client_ids.include?(client.id)), :id => chk_id ), 
              chk_id,
              h(client.company_name)
            ]
        }.join
      }.join :
      '<span class="active-scaffold_detail_value">No invoiceable clients are available for this date.</span>'
   
  end
end
