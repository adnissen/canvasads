def create_token(client, group=nil)
  token = {}
  token['total_earned'] = 0
  token['last_payout'] = 0
  token['next_payout'] = 0
  token['impressions'] = 0
  token['token'] = (0...16).map { (65 + rand(26)).chr }.join
  token['owner'] = session[:user]['email']
  token['group'] = group

  client[:tokens].insert_one token
  return 200
end

def update_payout(token, client)
  client[:tokens].find(:token => token['token']).update_one("$inc" => { :total_earned =>  0.001 })
  client[:tokens].find(:token => token['token']).update_one("$inc" => { :next_payout =>  0.001 })
  client[:tokens].find(:token => token['token']).update_one("$inc" => { :impressions =>  1 });
end

def update_token_group(client, token, group)
  client[:tokens].find(:token => token['token']).update_one("$set" => { :group => group['_id'] })
  return 200
end
