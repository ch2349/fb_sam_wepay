class User < ActiveRecord::Base
  has_many :microposts, dependent: :destroy
  has_many :active_relationships, class_name: "Relationship",
                                  foreign_key: "follower_id",
                                  dependent: :destroy
  has_many :passive_relationships, class_name: "Relationship",
                                  foreign_key: "followed_id",
                                  dependent: :destroy

  has_many :following, through: :active_relationships, source: :followed

  has_many :followers, through: :passive_relationships, source: :follower

                                  
  attr_accessor :remember_token, :activation_token, :reset_token
  before_save :downcase_email
  before_create :create_activation_digest 
  validates(:name, presence: true, length: { maximum: 50 })
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates(:email, presence:   true,
                    length:     {maximum: 200},
                    format:     { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false })
  
  has_secure_password
  validates :password, length: { minimum: 6 }, allow_blank: true

  has_many :authorizations

  
#Returns the hash digest of the given string.
  def User.digest(string)
  	cost=ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
  	                                            BCrypt::Engine.cost
  	BCrypt::Password.create(string,cost:cost)
  end
  
#Retrurn a random token.
  def User.new_token
    SecureRandom.urlsafe_base64
  end


#Remember a user in the database for use in persistent sessions.
  def remember
    self.remember_token=User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end
  
 #Returns true if the given token matches the digest. 
def authenticated?(attribute, token)
    digest=send("#{attribute}_digest")
     return false if digest.nil?
     BCrypt::Password.new(digest).is_password?(token)
end
  
#Forget a user.
  def forget
    update_attribute(:remember_digest,nil)
  end



#Activate an account.
  def activate
    update_attribute(:activated, true)
    update_attribute(:activated_at, Time.zone.now)

  end

#Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end


#Sets the password reset attributes.

def create_reset_digest
  self.reset_token=User.new_token
  update_attribute(:reset_digest, User.digest(reset_token))
  update_attribute(:reset_sent_at,Time.zone.now)
end





#sends password reset email.
def send_password_reset_email
  UserMailer.password_reset(self).deliver_now
end



     


        #Returns a user's status feeds.
         def feed
            following_ids= "SELECT followed_id FROM relationships 
                           WHERE follower_id = :user_id"
             Micropost.where("user_id IN (#{following_ids}) OR user_id = :user_id",user_id: id)
         end


         #follows a user.
         def follow(other_user)
          active_relationships.create(followed_id: other_user.id)
         end


        # Unfollows a user.
         def unfollow(other_user)
             active_relationships.find_by(followed_id: other_user.id).destroy
             end 
          
        #Returns true if the current user is following the other user.
        def following?(other_user)
          following.include?(other_user)
        end


 #returns true if a password reset has expired
 def password_reset_expired?
           reset_sent_at < 2.hours.ago
      end




# get the authorization url for this farmer. This url will let the farmer
# register or login to WePay to approve our app.

# returns a url
def wepay_authorization_url(redirect_uri)
  WEPAY.oauth2_authorize_url(redirect_uri, self.email, self.name)
end

# takes a code returned by wepay oauth2 authorization and makes an api call to generate oauth2 token for this farmer.
def request_wepay_access_token(code, redirect_uri)
  response = WEPAY.oauth2_token(code, redirect_uri)
  if response['error']
    raise "Error - "+ response['error_description']
  elsif !response['access_token']
    raise "Error requesting access from WePay"
  else
    self.wepay_access_token = response['access_token']
    self.save

    #create wepay account
    self.create_wepay_account
  end
end

def has_wepay_access_token?
  !self.wepay_access_token.nil?
end

# makes an api call to WePay to check if current access token for farmer is still valid
def has_valid_wepay_access_token?
  if self.wepay_access_token.nil?
    return false
  end
  response = WEPAY.call("/user", self.wepay_access_token)
  response && response["user_id"] ? true : false
end



def has_wepay_account?
  self.wepay_account_id != 0 && !self.wepay_account_id.nil?
end

# creates a WePay account for this farmer with the farm's name
def create_wepay_account
  if self.has_wepay_access_token? && !self.has_wepay_account?
    params = { :name => self.name, :description => " User donate " + self.donate_amount.to_s }     
    response = WEPAY.call("/account/create", self.wepay_access_token, params)

    if response["account_id"]
      self.wepay_account_id = response["account_id"]
      return self.save
    else
      raise "Error - " + response["error_description"]
    end

  end   
  raise "Error - cannot create WePay account"
end













# creates a checkout object using WePay API for this farmer
def create_checkout(redirect_uri)
  # calculate app_fee as 10% of produce price
  #app_fee = self.produce_price * 0.1
app_fee=0
  params = {
    :account_id => self.wepay_account_id,
    :short_description => "Donate from #{self.name}",
    :type => :GOODS,
    :amount => self.donate_amount,      
    :app_fee => app_fee,
    :fee_payer => :payee,     
    :mode => :iframe,
    :redirect_uri => redirect_uri
  }
  response = WEPAY.call('/checkout/create', self.wepay_access_token, params)

  if !response
    raise "Error - no response from WePay"
  elsif response['error']
    raise "Error - " + response["error_description"]
  end

  return response
end







  private 

  #Converts email to all lower_case
     def downcase_email
      self.email=email.downcase
    end

#Creates and assigns the activation token and digest.
    
    def create_activation_digest
      self.activation_token=User.new_token
      self.activation_digest=User.digest(activation_token)
    end


end