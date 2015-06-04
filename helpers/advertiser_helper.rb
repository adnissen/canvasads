def create_advertiser(username, password, email)
  Advertiser.new(username, password, email).save!
  return 200
end
