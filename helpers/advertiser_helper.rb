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
