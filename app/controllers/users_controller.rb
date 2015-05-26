class UsersController < ApplicationController
before_action :logged_in_user, only: [:index, :edit, :update, :destroy, :following, :followers, :donate,:give]
before_action :correct_user, only:[:edit, :update,:donate,:give]
before_action :admin_user,    only: :destroy
  
  


  def index
    @users=User.paginate(page: params[:page])
  end  


  def donate
     
     
  end


  def give
     if @user.update_attribute(:donate_amount,params[:user][:donate_amount])
        flash[:success]="Thanks for the donation"
        redirect_to "/users/buy/#{@user.id}"

      else
       render 'donate'
      end

  end


  def show
    @user = User.find(params[:id])
    @microposts=@user.microposts.paginate(page:params[:page])
  end

  def new
  	@user=User.new

  end


  def create
  	@user=User.new(user_params)
    
  	if @user.save
     @user.send_activation_email
      log_in(@user) 
      #@micropost=@user.microposts.create!(content: "hello world")
            flash[:info]="Please check your email to activate your account."
      
      
        redirect_to root_url
        #redirect_to user_url(@user) 
         #@user.send_activation_email
      else
        render 'new'
      end
    end

  def edit
    
  end
   
  def update
    
      if @user.update_attributes(user_params)
        flash[:success]="Profile updated"
        redirect_to @user

      else
       render 'edit'
      end
  end
    

  def destroy
    User.find(params[:id]).destroy
    flash[:success]="User deleted"
    redirect_to users_url
  end




  def following
    @title= "Following"
    @user =User.find(params[:id])
    @users =@user.following.paginate(page: params[:page])
    render 'show_follow'
  end

  def Followers
    @title= "Followers"
    @user =User.find(params[:id])
    @users= @user.followers.paginate(page: params[:page])
    render 'show_follow'
   end


# GET /users/oauth/1
def oauth
  if !params[:code]
    return redirect_to('/')
  end

  redirect_uri = url_for(:controller => 'users', :action => 'oauth', :user_id => params[:user_id], :host => request.host_with_port)
  @user = User.find(params[:user_id])
  begin
    @user.request_wepay_access_token(params[:code], redirect_uri)
  rescue Exception => e
    error = e.message
  end

  if error
    redirect_to @user, alert: error
  else
    redirect_to @user, notice: 'We successfully connected you to WePay!'
  end
end







# GET /users/buy/1
def buy
  redirect_uri = url_for(:controller => 'users', :action => 'payment_success', :user_id => params[:user_id], :host => request.host_with_port)
  @user = User.find(params[:user_id])
  begin
    @checkout = @user.create_checkout(redirect_uri)
  rescue Exception => e
    redirect_to @user, alert: e.message
  end
end



# GET /users/payment_success/1
def payment_success
  @user = User.find(params[:user_id])
  if !params[:checkout_id]
    return redirect_to @user, alert: "Error - Checkout ID is expected"
  end
  if (params['error'] && params['error_description'])
    return redirect_to @user, alert: "Error - #{params['error_description']}"
  end
  redirect_to @user, notice: "Thanks for the donation! You should receive a confirmation email shortly."
end











    private
    

  


    def user_params
      params.require(:user).permit(:name,:email,:password,:password_confirmation,:donate_amount)
    end 

  
  #Before filters
  

    #Confirms the correct user.
       def correct_user
        @user=User.find(params[:id])
         redirect_to(root_url) unless current_user?(@user)
         
       end

     #Confrims an admin user.
       def admin_user
       redirect_to(root_url) unless current_user.admin?
         
       end







end

