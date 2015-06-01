require 'bcrypt'

def create_advertiser(client, username, password, email)
  advertiser = {}
  advertiser['username'] = username
  advertiser['password'] = BCrypt::Password.create(password)
  advertiser['email'] = email

  if client[:advertisers].find(:email => email).count != 0
    return "error: advertiser already created"
  end

  client[:advertisers].insert_one advertiser
  "advertiser created"
end

def create_token(client)
  token = {}
  token['total_earned'] = 0
  token['last_payout'] = 0
  token['next_payout'] = 0
  token['impressions'] = 0
  token['token'] = (0...16).map { (65 + rand(26)).chr }.join
  token['owner'] = session[:user]['email']

  client[:tokens].insert_one token
  token['token']
end

def update_payout(token)
  client[:tokens].find(:token => token['token']).update_one("$inc" => { :total_earned =>  0.001 })
  client[:tokens].find(:token => token['token']).update_one("$inc" => { :next_payout =>  0.001 })
  client[:tokens].find(:token => token['token']).update_one("$inc" => { :impressions =>  1 });
end
