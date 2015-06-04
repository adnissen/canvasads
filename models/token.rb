require_relative 'JSONable'

class Token < JSONable
  def initialize(owner)
    @total_earned = 0
    @last_payout = 0
    @next_payout = 0
    @impressions = 0
    @group = ''
    @owner = owner

    @token = (0...16).map { (65 + rand(26)).chr }.join
  end
end
