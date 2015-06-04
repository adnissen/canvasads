def add_impression(ad)
  Ad.find_by_id(ad.id).add_impression
end

def create_ad(name, budget, content, end_date)
  ad = Ad.new(name, budget, content, session[:user].email)
  ad.save!
  return 200
end

def update_ad(id, content)
  ad = Ad.find_by_id(id)
  return 'error, invalid credentials' unless session[:user].email == ad.owner
  ad.content = content
  ad.save!
  'ad updated'
end

def delete_ad(id)
  ad = Ad.find_by_id(id)
  return 'error, invalid credentials' unless session[:user].email == ad.owner
  Ad.delete_byid(id)
  'ad deleted'
end
