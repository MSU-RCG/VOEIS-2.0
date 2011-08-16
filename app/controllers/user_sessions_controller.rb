class UserSessionsController < ApplicationController

  # before_filter :require_no_user, :only => [:new, :create]
  # before_filter :require_user,    :only => [:destroy]

  ##
  # Redirects to new user_session action
  #
  # @example
  #   get /user_sessions/new
  #
  # @return [Redirect] Redirects to login url
  #
  # @author lamb
  #
  # @api public
  def show
    redirect_to(:back)# login_url
  end

  ##
  # Renders a login page
  #
  # @example
  #   get /user_sessions/new
  #   get /login
  #
  # @return [HTML] The login page
  #
  # @author lamb
  #
  # @api public
  def new
    redirect_to(:back)
    #render :action => 'new'
  end

  ##
  # Renders a login page
  #
  # @example
  #   get /user_sessions/new
  #   get /login
  #   get /unauthenticated
  #
  # @return [HTML] The login page
  #
  # @author lamb
  #
  # @api public
  alias :unauthenticated :new

  ##
  # Logs a user in or rerenders the login page
  #
  # @example
  #   post /user_sessions
  #
  # @return [Redirect or HTML]
  #   Redirects or rerenders the login page
  #
  # @author lamb
  #
  # @api public
  def create
    flash[:error] = "Invalid Login Credentials!"
    if authenticate!
      flash[:notice] = "Login successful!"
      flash[:error] = ""
      #redirect_back_or_default root_url
    else
      #render :action => :new
      flash[:error] = "Invalid Login Credentials!"
    end
    redirect_to(:back)
  end
  
  ##
  # Logs a user in and returns their API key
  #
  # @example
  #   https://voeis.msu.montana.edu/user_session/get_api_key.json?user_session[login]=mylogin&user_session[password]=mypassword
  #
  # @return [JSON String] api_key
  # 
  #
  # @author Sean Cleveland
  #
  # @api public
  def get_api_key
    @api = Hash.new
    if authenticate!
      if current_user.api_key.nil?
        current_user.generate_new_api_key!
      end
      @api = {:api_key => current_user.api_key}
    else
      @api = {:error => "The combination of login and password is invalid."}
    end
    respond_to do |format|
      format.json do
        render :json => @api.as_json, :callback => params[:jsoncallback]
      end
    end
  end

  ##
  # Logs out a user
  #
  # @example
  #   delete /user_sessions/
  #   delete /logout
  #
  # @return [HTML] The login page
  #
  # @author lamb
  #
  # @api public
  def destroy
    logout
    flash[:notice] = "Logout successful!"
    redirect_back_or_default root_url
  end

end