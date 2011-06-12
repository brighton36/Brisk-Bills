module Admin::ClientRepresentativesHelper
  include Admin::HasCredentialColumnHelper

  alias :client_representative_password_form_column :password_form_column
  alias :client_representative_login_enabled_form_column :login_enabled_form_column

  def client_representative_clients_form_column(record, options)
    list_i = nil

    # Keeps our queries down by 'caching' it here:
    client_ids = record.client_ids
    
    Client.find(:all, :order => 'company_name ASC').in_groups_of((Client.count(:all).to_f/3).ceil, false).collect{ |group|
      '<ul class="checkbox-list">'+
        group.collect{ |client|
          list_i = (list_i) ? list_i+1 : 0
          chk_name = "%s[%d][id]" % [options[:name], client.id]
          chk_id = "%s_client_%d" % [options[:id], client.id]

          '<li>%s<label for="%s">%s</label></li>' % [ 
            check_box_tag(chk_name, client.id, client_ids.include?(client.id), :id => chk_id ), 
            chk_id,
            h(client.company_name)
          ]
        }.join+
      '</ul>'
    }.join
  end

end
