def create_token(group=nil)
  token = Token.new session[:user]['email']
  Database.client[:tokens].insert_one token.to_hash
  return 200
end

def update_payout(token)
  Database.client[:tokens].find(:token => token['token']).update_one("$inc" => { :total_earned =>  0.001 })
  Database.client[:tokens].find(:token => token['token']).update_one("$inc" => { :next_payout =>  0.001 })
  Database.client[:tokens].find(:token => token['token']).update_one("$inc" => { :impressions =>  1 });
end

def update_token_group(token, group)
  Database.client[:tokens].find(:token => token['token']).update_one("$set" => { :group => group['_id'] })
  return 200
end
