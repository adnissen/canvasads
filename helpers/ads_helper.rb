def add_impression(ad, client)
  client[:ads].find(:_id => ad['_id']).update_one("$inc" => { :inventory => -1 })
  client[:ads].find(:_id => ad['_id']).update_one("$inc" => { :impressions => 1 })
end

def create_ad(client, name, budget, content, end_date)
  ad = Ad.new(name, budget, content, session[:user]['email']);

  client[:ads].insert_one ad.to_hash
  return 200
end

def update_ad(client, _id, content)
  return 'error, invalid credentials' unless session[:user]['email'] == client[:ads].find(:_id => _id).first['owner']
  Ad.find_by_id(_id).update_content content
  'ad updated'
end

def delete_ad(client, _id)
  return 'error, invalid credentials' unless session[:user]['email'] == client[:ads].find(:_id => _id).first['owner']
  client[:ads].find(:_id => _id).delete_one
  'ad deleted'
end

def track_engage(ad, client)
  client[:ads].find(:_id => ad['_id']).update_one("$inc" => { :engagements => 1 })
  client[:tokens].find(:token => params['token']).update_one("$inc" => { :engagements => 1 }) if params['token']
end
