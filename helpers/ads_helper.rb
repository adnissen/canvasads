def add_impression(ad)
  Ad.find_by_id(ad['_id']).add_impression
end

def create_ad(client, name, budget, content, end_date)
  ad = Ad.new(name, budget, content, session[:user]['email']);

  client[:ads].insert_one ad.to_hash
  return 200
end

def update_ad(_id, content)
  ad = Ad.find_by_id(_id)
  return 'error, invalid credentials' unless session[:user]['email'] == ad.owner
  ad.update_content content
  'ad updated'
end

def delete_ad(_id)
  ad = Ad.find_by_id(_id)
  return 'error, invalid credentials' unless session[:user]['email'] == ad.owner
  Ad.delete_by_id(_id)
  'ad deleted'
end
