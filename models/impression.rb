require "date"
require_relative "JSONable"

#
# This class represents an impression
#
# @author: gtgettel
class Impression < JSONable
  attr_accessor :ad_id, :token, :group, :time, :ip, :hostname, :time_of_click

  def initialize(ad_id=0, token='', group=nil, ip='0', hostname='')
    @ad_id = ad_id # id of ad served during impression
    @token = token # token that requested ad
    @group = group # group of ad returned
    @ip = ip # ip address of requester
    @time = DateTime.now # current day for dashboard purposes
    @hostname = hostname # hostname of site that hosts ad
  end
end