class AuthenticationController < ApplicationController
  include ApplicationHelper

  layout 'public'

  # Login Messages
  MSG_INVALID_EMAIL  = "Invalid e-mail address. Let&#39;s try it again?"
  MSG_UNKNOWN_BUTTON = 'An unknown error occurred while processing your request. How very odd...'

  # Reset Messages
  MSG_MISMATCHED_PASSWORD = "Your passwords don&#39;t match. Try re-entering your password again, and make sure that both fields contain the same password."
  MSG_UNRECOGNIZED_EMAIL  = "Oh dear, there&#39;s no record of this e-mail address in our database. Perhaps you mispelled this page&#39;s  address?" 
  MSG_BAD_TOKEN           = 'Invalid reset token. Perhaps you&#39;re having this problem because you arrived here by clicking the link on an outdated e-mail?'
  MSG_RESET_SUCCESS       = 'Password Successfully Reset. Please use your new password to Login.'

  def index
    redirect_to login_url
  end

  def login
    respond_to do |format|
      format.html do
        define_application_layout_variables
        @page_title = 'Sign-in'

        if @active_credential
          redirect_to @active_credential.default_post_login_url_to
        else     
          render :action => :login
        end
      end
      format.js do
        begin
          @flash_error = nil
          @button_press = 'sign_in_error'
          @button_press = params[:commit][0] if /^(login|email)$/.match(params[:commit][0])

          case @button_press
            when 'login'
              @active_credential = Credential.find_using_auth params[:email_address], params[:password]

              if @active_credential
                session[:credential_id] = @active_credential.id

                @redirect_to = session[:uncredentialed_request_uri]

                session[:uncredentialed_request_uri] = nil
              end
            when 'email'
              credential = Credential.find_by_email params[:email_address]

              if credential
                reset_token = credential.generate_reset_token!

                credential_name = (credential.user and credential.user.respond_to? :name) ? 
                  credential.user.name : 
                  credential.email_address

                mail = Notifier.deliver_reset_password_requested(
                  credential_name, 
                  credential.email_address,
                  reset_token,
                  request_full_host
                )
              else
                raise StandardError, MSG_INVALID_EMAIL
              end

            else
              raise StandardError, MSG_UNKNOWN_BUTTON
          end
        rescue
          @flash_error = $!
        ensure
          render :action => @button_press
        end
      end
    end
  end
  
  def logout
    session[:credential_id] = nil
    redirect_to login_url
  end
  
  def reset_password_via_token
    @email_address = params[:email_address][0]
    @token = params[:token]

    respond_to do |format|
      format.html do
        define_application_layout_variables
        @page_title = 'Reset Password'

        render :action => :reset_password_via_token
      end
      format.js do
        begin
          raise StandardError, MSG_MISMATCHED_PASSWORD if params[:password_verify] != params[:password]

          active_credential = Credential.find_by_email params[:email_address]

          raise StandardError, MSG_UNRECOGNIZED_EMAIL unless active_credential
          
          raise StandardError, MSG_BAD_TOKEN unless active_credential.reset_password_by_token!(params[:token], params[:password])
          
          flash[:notice] = MSG_RESET_SUCCESS
        rescue
          @flash_error = $!
        ensure
          render :action => :reset_password_via_token
        end
      end
    end
  end

  private

  def request_full_host
    server_address = "#{request.server_name}"
    if (
      (request.protocol == 'http://' and request.port != 80) or
      (request.protocol == 'https://' and request.port != 443)
    )
      server_address += ":#{request.port}" 
    end

    server_address
  end

end
