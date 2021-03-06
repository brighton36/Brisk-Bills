module ActionMailer
  module PartContainer
    # Add an inline attachment to a multipart message. 
    def inline_attachment(params, &block)
      params = { :content_type => params } if String === params
      params = { :disposition => "inline",
                 :transfer_encoding => "base64" }.merge(params)
      params[:headers] ||= {}
      params[:headers]['Content-ID'] = params[:cid]
      part(params, &block)
    end
  end

  class Part
    def to_mail(defaults)
      part = TMail::Mail.new

      if @parts.empty?
        part.content_transfer_encoding = transfer_encoding || "quoted-printable"
        case (transfer_encoding || "").downcase
          when "base64" then
            part.body = TMail::Base64.folding_encode(body)
          when "quoted-printable"
            part.body = [Utils.normalize_new_lines(body)].pack("M*")
          else
            part.body = body
        end

        # Always set the content_type after setting the body and or parts

        # CHANGE: treat attachments and inline files the same
        if content_disposition == "attachment" || ((content_disposition == "inline") && filename)
            part.set_content_type(content_type || defaults.content_type, nil,
            squish("charset" => nil, "name" => filename))
        else
          part.set_content_type(content_type || defaults.content_type, nil,
            "charset" => (charset || defaults.charset))    
        end  
                     
        part.set_content_disposition(content_disposition, squish("filename" => filename)) unless content_disposition.blank?
        headers.each {|k,v| part[k] = v }
        # END CHANGE

      else
        if String === body
          part = TMail::Mail.new
          part.body = body
          part.set_content_type content_type, nil, { "charset" => charset }
          part.set_content_disposition "inline"
          m.parts << part
        end
          
        @parts.each do |p|
          prt = (TMail::Mail === p ? p : p.to_mail(defaults))
          part.parts << prt
        end
        
        part.set_content_type(content_type, nil, { "charset" => charset }) if content_type =~ /multipart/
      end
    
      part
    end
  end
end

module ActionView
  module Helpers #:nodoc:
    module AssetTagHelper
      
      # Brisk-Bills Adjustment
      # This is a weird hack that fixes issues in produiction mode with inlineattachment - seems to work, so whatever?
      alias image_path_without_inline_attachment image_path
      def image_path(source)
        @part_container ||= @controller
        if @part_container.is_a?(ActionMailer::Base) or @part_container.is_a?(ActionMailer::Part)
          '/images/%s' % source
        else
          image_path_without_inline_attachment(source)
        end
      end
      # /Brisk-Bills
      
      def image_tag(source, options = {})
        options.symbolize_keys!
        
        @part_container ||= @controller
           
        if @part_container.is_a?(ActionMailer::Base) or @part_container.is_a?(ActionMailer::Part)
          file_path, basename, ext =/^.+?([^\/]+)\.([^\.]+)$/.match("#{RAILS_ROOT}/public#{image_path(source).split('?').first}").to_a

          cid = Time.now.to_f.to_s + "#{basename}@inline_attachment"
          
          @part_container.inline_attachment(:content_type => "image/#{ext}",
                                        :body         => File.open(file_path, 'rb').read,
                                        :cid          => "<#{cid}>",
                                        :disposition  => "inline")
          
          options[:src] = "cid:#{cid}"
          options[:alt] ||= basename.capitalize
        else
          options[:src] = image_path(source)
          options[:alt] ||= File.basename(options[:src], '.*').split('.').first.capitalize
        end
        
        if options[:size]
          options[:width], options[:height] = options[:size].split("x") if options[:size] =~ %r{^\d+x\d+$}
          options.delete(:size)
        end

        tag("img", options)
      end
    end
  end
end

class DummyClass
  def relative_url_root
    ""
  end
  
  def protocol
  "http"
  end

  def relative_url_root
  ""
  end
end

module ActionMailer #:nodoc:
  class Base
    def request
      DummyClass.new
    end
  end
end