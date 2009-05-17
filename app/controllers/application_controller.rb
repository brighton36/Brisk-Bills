# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  before_filter :validate_credentials

  def validate_credentials
    @active_credential = Credential.find session[:credential_id] if session[:credential_id]

    unless Credential.guest_permitted? params[:controller], params[:action]
      if @active_credential
        render :file => "#{RAILS_ROOT}/public/500.html" unless @active_credential.is_request_permitted?( params[:controller], params[:action] )
      else
        session[:uncredentialed_request_uri] = request.request_uri

        redirect_to login_url
      end
    end
  end
end
