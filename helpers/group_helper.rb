def create_group(name)
  group = {}
  group['ads'] = []
  group['name'] = name
  group['owner'] = session[:user]['email']
  group['_id'] = (0...16).map { (65 + rand(26)).chr }.join

  Database.client[:groups].insert_one group
  return group['_id']
end

def insert_ad_to_group(group, ad)
  Database.client[:groups].find(:_id => group['_id']).update_one("$push" => { :ads => ad['_id'] })
  return 200
end
