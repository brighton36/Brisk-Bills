module Admin::HasCredentialColumnHelper

  PASSWORD_ON_FOCUS_JS = "$(%s).observe('focus',function(event){"+
    "el = event.element();"+
    "old_password_values[%d] = el.value;"+
    "el.value = '';"+
  "});"
  PASSWORD_ON_BLUR_JS  = "$(%s).observe('blur', function(event){"+
    "el = event.element();"+
    "record_id = %d;"+
    "if (el.value == ''){el.value = old_password_values[record_id];} else {password_has_changed[record_id] = true;};"+
  "});"
  
  def form_remote_tag(*args)
    post_script = ''

    if @record and !@record.new_record? and @record.password_hash
      args[0][:before] = "if (password_has_changed[%d] == false) { $('%s').value = ''; }" % [ 
        @record.id, 
        password_input_id 
      ]

      post_script = 
        ('<script>'+
          'if (typeof(password_has_changed) == "undefined"){password_has_changed = [];old_password_values = [];};'+
          'password_has_changed[%d] = false;'+
        '</script>')  % @record.id
    end

    super(*args)+post_script
  end

  def password_form_column(record, input_name)
    password_field_tag(
      input_name, 
      ( record.password_hash ) ? 'secretsecret' : '', 
      :id => password_input_id,
      :size => 20
    )+javascript_tag( 
      [PASSWORD_ON_FOCUS_JS, PASSWORD_ON_BLUR_JS].collect{|js| js % [password_input_id.to_json, @record.id]}
    )
  end

  def login_enabled_form_column(record, input_name)
    select_tag(
      input_name, 
      options_for_select( 
        [ ["Yes", 'true'], ["No", 'false'] ], 
        (record.login_enabled.nil?) ? 'false' : record.login_enabled.to_s
      ),
      :id => 'record_login_enabled'
    )
  end

  def password_input_id()
    input_id = 'record_password'
    input_id += ('_%d' % @record.id) unless @record.new_record?
  end

end
