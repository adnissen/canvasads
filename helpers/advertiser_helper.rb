require 'bcrypt'

def create_advertiser(username, password, email)
  advertiser = {}
  advertiser['username'] = username
  advertiser['password'] = BCrypt::Password.create(password)
  advertiser['email'] = email

  if Database.client[:advertisers].find(:email => email).count != 0
    return 406
  end

  Database.client[:advertisers].insert_one advertiser
  return 200
end
