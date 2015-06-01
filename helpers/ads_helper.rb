def add_impression(ad, client)
  client[:ads].find(:_id => ad['_id']).update_one("$inc" => { :inventory => -1 })
  client[:ads].find(:_id => ad['_id']).update_one("$inc" => { :impressions => 1 })
end

def create_ad(client, name, budget, content, end_date)
  ad = {}
  ad['name'] = name
  ad['budget'] = budget
  ad['impressions'] = 0
  ad['inventory'] = (budget.to_i / 1.50) * 1000
  ad['content'] = content
  ad['active'] = true
  ad['owner'] = session[:user]['email']
  ad['_id'] = (0...8).map { (65 + rand(26)).chr }.join

  client[:ads].insert_one ad
  'ad inserted'
end

def update_ad(client, _id, content)
  return 'error, invalid credentials' unless session[:user]['email'] == client[:ads].find(:_id => _id).first['owner']
  client[:ads].find(:_id => _id).update_one("$set" => { :content => content })
  'ad updated'
end

def delete_ad(client, _id)
  return 'error, invalid credentials' unless session[:user]['email'] == client[:ads].find(:_id => _id).first['owner']
  client[:ads].find(:_id => _id).delete_one
  'ad deleted'
end
