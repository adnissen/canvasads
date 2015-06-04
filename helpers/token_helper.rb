def update_payout(token)
  token.total_earned = token.total_earned + 0.001
  token.next_payout = token.next_payout + 0.001
  token.impressions = token.impressions + 1
  token.save!
  return 200
end

def update_token_group(token, group)
  token = Token.find_by_token token.token
  token.group = group.id
  token.save!
  return 200
end
