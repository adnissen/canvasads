def add_impression(ad)
  Ad.find_by_id(ad.id).add_impression
end

def create_ad(name, budget, content, end_date)
  ad = Ad.new(name, budget, content, session[:user].email)
  ad.save!
  return 200
end

def update_ad_budget(id, budget)
  ad = Ad.find_by_id id
  ad.budget += budget
  ad.inventory += (budget.to_f / 1.10) * 1000
  ad.save!
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
  Ad.delete_by_id(id)
  'ad deleted'
end
