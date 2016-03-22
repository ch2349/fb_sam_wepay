# http://code.tutsplus.com/articles/how-to-use-omniauth-to-authenticate-your-users--net-22094
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET']
end