class SessionsController < ApplicationController

  def new
  end

  def facebook
      auth_hash=request.env['omniauth.auth']
      @authorization=Authorization.find_by_provider_and_uid(auth_hash["provider"],auth_hash["uid"])
      if @authorization
                 log_in(@authorization.user)
             redirect_to @authorization.user
                
    else
             
             user=User.new(name:auth_hash["info"]["name"],email: auth_hash["info"]["email"],
              password:auth_hash["info"]["email"], password_confirmation:auth_hash["info"]["email"],
               oauth_token: auth_hash["credentials"]["token"],oauth_expires_at:auth_hash["credentials"]["expires_at"])
             @auth=user.authorizations.build(provider: auth_hash["provider"],uid:auth_hash["uid"])
             user.save
             @auth.save
             log_in(user)
             redirect_to user
           
     end
  end



  def create
    
    
     user = User.find_by(email: params[:session][:email].downcase)
             if user && user.authenticate(params[:session][:password])
                       # Log the user in and redirect to the user's show page.
                    if user.activated?
                       log_in(user)
                       params[:session][:remember_me]=='1' ? remember(user) : forget(user)
                       redirect_back_or user
                    else
                      message ="Account not activated. "
                      message +="check your email for the activation link."
                      flash[:warning] = message
                      redirect_to root_url
                    end
             else 
                  flash.now[:danger]='Invalid email/password combination'
                  render 'new'

             end
    

end
  


  def destroy
    log_out if logged_in?
    redirect_to root_url
  end
  
    






end
