module Admin::ClientRepresentativesHelper
  include Admin::HasCredentialColumnHelper
    
  def clients_form_column(record, input_name)
    list_i = nil
    
    Client.find(:all, :order => 'company_name ASC').in_groups_of((Client.count(:all).to_f/3).ceil, false).collect{ |group|
      '<ul class="checkbox-list">'+
        group.collect{ |client|
          list_i = (list_i) ? list_i+1 : 0
          chk_name = "%s[%d][id]" % [input_name, client.id]
          
          '<li>%s<label for="%s[%d][id]">%s</label></li>' % [ 
            check_box_tag(chk_name, client.id, record.client_ids.include?(client.id) ), 
            chk_name,
            list_i,
            client.company_name
          ]
        }.join+
      '</ul>'
    }.join
  end
  
  
  
end
