#
# The functions in this file use the Geocoder gem to
# get the location of ad viewers
#
# @author: gtgettel

require "geocoder"
require_relative "../models/user"

#
# Returns a result object with location data (not 100% on how geocoder works)
#
# @params: request - sinatra request
# @return: reserved_result - returns result object if available else nil
#
def find_location_by_ip(request)
  reserved_result = request.location
  # check to ensure api returned data and not 403 or timeout
  if reserved_result
    reserved_result
  else
    nil
end

#
# Uses a thread find location, then kills thread
# 
# @params: request - sinatra request
# @params: user_ip - user ip that needs location
# @return: N/A
#
def find_location_use_thread(request, user_ip)
  location_obj = find_location_by_ip(request) # get location data
  if location_obj
    # update first user in db there is valid location data
    Database.client[:users].update(
      { ip: user.ip },
      {
        "$set" => {
          location_last_hour_zip: location_obj.postal_code,
          location_last_hour_state: location_obj.state,
          location_last_hour_city: location_obj.city,
          location_last_hour_country_code: location_obj.country_code
        },
        multi: false
      }
    )
  end
  Thread.exit # exit thread
end