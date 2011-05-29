module AuthenticationHelper

  def flash_notice(type, notice)
    '<div class="clearfix flash-result %s">%s<span>%s</span></div>' % [ 
      "notice-#{type}",
      image_tag('notice-%s.gif' % type.to_s, :size => '21x17'), 
      notice
    ]
  end

  def stop_loading_indicator
    "$('loading_indicator').style.visibility = 'hidden';"
  end

  def flash_blind_down(options = {})
    options[:duration] ||= 0.2
    options[:queue] ||= 'end'
    
    if options[:message]
      options[:beforeStart] = ("function(){ Element.update('flash-notice', '%s'); }" % options[:message] )
      
      options.delete :message
    end

    "new Effect.BlindDown('flash-notice', %s );" % scriptaculize_args(options)
  end

  def scriptaculize_args(h)
    args = []
    h.each_pair do |k,v|
      v = (/^(before|after)/.match(k.to_s)) ? v : v.to_json

      args << "%s: %s" % [k, v]
    end

    "{%s}" % args.join(', ')
  end

  def welcome_form_box(name, &block)
    logo_w=120

    concat('%s<div id="%s_welcome" class="welcome_box clearfix"><h1>%s</h1>%s' % [ 
      image_tag('brisk-bills-logo.gif', :size => '%dx%d' % [logo_w, 300.to_f/316*logo_w], :alt => "Brisk Bills"),
      name.underscore, 
      h(name), 
      image_tag('login-form-spinner.gif', :size => '32x32', :style => 'visibility: hidden', :id => 'loading_indicator') 
    ])
    form_remote_tag(
      {
      :url => url_for(:action => params[:action]), 
      :before => "$('loading_indicator').style.visibility = 'visible'; new Effect.BlindUp('flash-notice', {duration: 0.20 });",
      },
      &block
    )
    concat('</div>')
  end

end
