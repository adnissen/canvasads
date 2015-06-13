#
# These functions implement the logic behind selecting ads
#
# @author: gtgettel

require 'date'
require 'mongo'
require 'time_difference'
require_relative '../models/ad'
require_relative '../util'


#
# Calculates the score of the ad
# score = -(Log10(1-random_number[0..1])) * (ad_inventory/sum_of_inventory) / Max[ad_hours_remaining - 12, .01]
#
# @params: ad - ad being scored
# @params: inventory_sum - sum of the inventory of active ads in group or of all ads
# @return: score - determined by algorithm
#
def calculate_score(ad, inventory_sum)
  rand_num_with_log = Math.log10(1 - Random.rand()) # generate random float between 0 and 1
  percent_impressions_wanted = ad.inventory / inventory_sum # algorithm is based on ratio between ads needed
  ad_time_remaining = TimeDifference.between((DateTime.parse(ad.end_time).to_time), DateTime.now.to_time).in_hours          # and time remaining for campaign
  ad_hours_remaining = (ad_time_remaining - 12) * 0.01
  return (-1) * rand_num_with_log * percent_impressions_wanted / ad_hours_remaining # combine pieces to get score
end

#
# Compares the scores of all ads in an array and finds the greates
#
# @params: ads_array - array of ad objects
# @return: highest_score_ad - ad object with highest score
#
def compare_ad_scores(ads_array)
  inventory_sum = 0
  # calculate sum of ad inventory
  ads_array.each do |ad|
    inventory_sum += ad.inventory
  end

  highest_score_ad = nil
  highest_score = 0
  # for each active ad
  ads_array.each do | ad_ar |
    ad_ar_score = calculate_score(ad_ar, inventory_sum) # find score
    if ad_ar == nil
      highest_score_ad = ad_ar
      highest_score = ad_ar_score
    elsif ad_ar_score >= highest_score # if greatest score so far
      highest_score_ad = ad_ar
      highest_score = ad_ar_score
    end
  end

  return highest_score_ad
end

#
# Selects the ad to be returned after a request from a certain group
#
# @params: group - group ad will be selected from
# @return: ad impression or nil if no ads are active in the group
#
def ad_fetcher_by_group(group)
  ads_array = []

  # find all active ads in a group
  group.ads.each do |ad|
    ad = Ad.find_by_id ad
    if ad.active
      ads_array << ad
    end
  end

  # compare scores if there are ads or return nil if none
  if ads_array.any?
    return compare_ad_scores(ads_array)
  else
    return nil
  end
end


#
# Selects the ad to be returned after a request
#
# @params: N/A
# @return: ad impression or nil if no ads are active
#
def ad_fetcher()
  ads = Database.client[:ads].find(:active => true) # get all active ads
  ads_array = []
  # convert JSON ads to object instances of Ad
  ads.each do |ad|
    if ad['active']
      new_ad = Ad.find_by_id ad['id']
      ads_array << new_ad
    end
  end

  # compare scores if there are ads or return nil if none
  if ads_array.any?
    return compare_ad_scores(ads_array)
  else
    return nil
  end
end
