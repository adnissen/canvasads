def create_group(client, name)
  group = {}
  group['ads'] = []
  group['name'] = name
  group['owner'] = session[:user]['email']
  group['_id'] = (0...16).map { (65 + rand(26)).chr }.join

  client[:groups].insert_one group
  return 200
end

def insert_ad_to_group(client, group, ad)
  client[:groups].find(:_id => group['_id']).update_one("$push" => { :ads => ad['_id'] })
  return 200
end
