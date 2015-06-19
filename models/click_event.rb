require "date"
require_relative "JSONable"

#
# This class represents a user clicking an ad
# Tracked by click_events collection in db
#
# @author: gtgettel
class ClickEvent < JSONable
  attr_accessor :ip, :click_time, :hostname, :ad_id

  def initialize(ip="0", hostname="", ad_id="")
    @ip = ip # ip address of user
    @click_time = DateTime.now # time of click
    @hostname = hostname # site name
    @ad_id = ad_id # id of ad clicked
  end

end
