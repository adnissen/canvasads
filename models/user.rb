require "date"
require_relative "JSONable"

#
# This class represents a user for tracking purposes
#
# @author: gtgettel
class User < JSONable
  attr_accessor :ip, :location_last_hour_zip, :location_last_hour_state,
    :location_last_hour_city, :location_last_hour_country_code,
    :last_time_seen, :user_agents

  def initialize(ip="0", location_last_hour_zip=nil,
                location_last_hour_state=nil, location_last_hour_city=nil,
                location_last_hour_country_code=nil, user_agents=[]
    )
    @ip = ip # ip address of user
    # most recent location: zip, state, city, country code
    @location_last_hour_zip = location_last_hour_zip
    @location_last_hour_state = location_last_hour_state
    @location_last_hour_city = location_last_hour_city
    @location_last_hour_country_code = location_last_hour_country_code
    @last_time_seen = DateTime.now # last time user was sent an ad
    @user_agents = user_agents # array of all devices associtaed with user
  end

end
