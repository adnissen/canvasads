require_relative 'JSONable'

class Token < JSONable
  attr_accessor :owner, :next_payout, :total_earned, :impressions, :group, :token, :unfilled, :fill_rate

  def initialize(owner='')
    @total_earned = 0
    @last_payout = 0
    @next_payout = 0
    @impressions = 1
    @unfilled = 0
    @fill_rate = 0
    @group = ''
    @owner = owner

    @token = (0...16).map { (65 + rand(26)).chr }.join
  end

  def save!
    if Token.find_by_token @token
      Database.client[:tokens].find(:token => @token).replace_one(self.to_hash)
    else
      Token.insert_token self
    end
  end

  def no_fill
    @unfilled += 1
    @fill_rate = 100 - ((@unfilled / @impressions) * 100)
    self.save!
  end

  def self.total_unfilled
    tokens = Database.client[:tokens].find
    total = 0
    tokens.each do |token|
      total += (token['unfilled'] || 0)
    end
    total
  end

  def self.find_by_token(id)
    token = Database.client[:tokens].find(:token => id).first
    if token
      new_token = Token.new
      new_token.from_json! token.to_json
      new_token
    else
      nil
    end
  end

  def self.insert_token(token)
    Database.client[:tokens].insert_one token.to_hash
  end
end
