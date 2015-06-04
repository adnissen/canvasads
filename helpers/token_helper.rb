def create_token(client, group=nil)
  token = Token.new session[:user]['email']
  client[:tokens].insert_one token.to_hash
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
