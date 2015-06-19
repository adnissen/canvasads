require "sinatra"
require "mongo"
require "pry"
require "json"
require "keen"
require "newrelic_rpm" if ENV['NEW_RELIC_APP_NAME']
require "time_difference"
require_relative "helpers/ads_helper"
require_relative "helpers/advertiser_helper"
require_relative "helpers/application_helper"
require_relative "helpers/token_helper"
require_relative "helpers/group_helper"
require_relative "helpers/ad_fetcher"
require_relative "models/ad"
require_relative "models/JSONable"
require_relative "models/token"
require_relative "models/advertiser"
require_relative "models/group"
require_relative "models/url"
require_relative "models/impression"
require_relative "models/click_event"
require_relative "models/user"
require_relative "util"


enable :sessions
set :session_secret, 'adsfkljadsufljsadlft'
set :protection, :except => :frame_options
Mongo::Logger.logger.level = Logger::WARN

configure :development do
  require "better_errors"
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
end

get '/' do
  send_file "public/index.html"
end

get '/advertisers/new' do
  return 406 unless params['username'] && params['password'] && params['email']
  create_advertiser(params['username'], params['password'], params['email'])
end

get '/login' do
  return 406 unless log_in_with_password(params['email'], params['password'])
  return 200
end

get '/logout' do
  log_out
  'logged out'
end

get '/tokens/new' do
  return 406 unless logged_in?
  return 406 unless admin?

  token = Token.new(session[:user].email)
  token.save!
  token.token
end

post '/engage' do
  # check for last seen ad in session
  return 406 unless !session[:last_seen_ad].nil?
  ad = Ad.find_by_id session[:last_seen_ad]
  return 404 unless ad

  # update ad stats
  ad.engagements += 1
  ad.save!

  # create a Click_Event and add to db
  click = ClickEvent.new(request.ip, request.hostname, ad.id)
  Database.client[:click_events].insert_one click

  return 200
end

post '/tokens/new' do
  return 406 unless logged_in?
  return 406 unless admin?

  token = Token.new(session[:user].email)
  token.save!
  return 200
end

get '/tokens/:token' do
  if params['redirect'] && !valid_bypass_url?(params['redirect'])
    return 406 unless logged_in?
    return 405 unless params['token']
    token = Token.find_by_token params['token']
    return 406 unless token && token.owner == session[:user].email
  else
    token = Token.find_by_token params['token']
  end

  token.to_json.to_s
end

post '/tokens/:token/group/update' do
  return 406 unless logged_in?
  return 405 unless params['token'] && params['group']
  token = Token.find_by_token params['token']
  return 406 unless token && token.owner == session[:user].email
  group = Group.find_by_id params['group']
  return 404 unless group

  update_token_group token, group
end

get '/ads' do
  # check for token
  return 406 unless params['token']
  token = Token.find_by_token params['token']
  return 406 unless token

  # match token to group
  group = Group.find_by_id token.group

  # look for user in database
  found_user = Database.client[:users].find(ip: request.ip).first
  if found_user # user already exists
    user = User.new # convert to object
    user.from_json! found_user.to_json
    if !user.user_agent.include?(request.user_agent.to_s) # check user agent
      # update first user with new user agent list
      user.user_agents.push(request.user_agent.to_s)
      Database.client[:users].update(
        { ip: user.ip },
        {
          "$set" => {
            user_agents: user.user_agents
          },
          multi: false
        }
      )
    end
    if TimeDifference(
      DateTime.parse(user.last_time_seen).to_time,
      DateTime.now.to_time).in_minutes > 60 # has it been an hour since seen
      # spawn thread to handle geocoder api request
      thr = Thread.new { find_location_use_thread(request, user.ip) }
    end
  else # user does not exist
    # create and handle new user
    user = User.new(request.ip, nil ,nil ,nil ,nil ,[request.user_agent.to_s])
    Database.client[:users].insert_one user.to_hash
    thr = Thread.new { find_location_use_thread(request, user.ip) }
  end

  # fetch ad
  if !group
    ad = ad_fetcher
  else
    ad = ad_fetcher_by_group group
  end

  # return ad or no_fill
  if ad
    ad.add_impression
    update_payout(token)

    # create impression
    if group
      impression = Impression.new ad.id, token.token, group.id,
        request.ip, request.host
    else
      impression = Impression.new ad.id, token.token, nil,
        request.ip, request.host
    end

    # add impression to database
    Database.client[:impressions].insert_one impression.to_hash

    # update session
    session[:last_seen_ad] = ad.id
    ad.content
  else
    token.no_fill
    send_file 'views/ads/nofill.html'
  end
end

get '/ads/ad/:id' do
  ad = Database.client[:ads].find(:id => params['id']).first
  return 'ad not found' unless ad
  add_impression(ad)
  ad['content']
end

get '/ads/ad/:id/dashboard' do
  if params['redirect'] && !valid_bypass_url?(params['redirect'])
    return 406 unless logged_in?
    return 406 unless logged_in?
  end
  ad = Database.client[:ads].find(:id => params['id']).first
  return 'ad not found' unless ad

  groups = Database.client[:groups].find(:ads => {"$in" => {}})

  return ad.to_json if params['format'] == 'json'
  send_file 'views/ads/dashboard.html'
end

get '/ads/ad/:id/update' do
  return 406 unless logged_in?
  return 406 unless admin?
  send_file 'views/ads/update.html'
end

post '/ads/ad/:id/update' do
  return 406 unless logged_in?
  return 406 unless admin?
  return 406 unless params['content']
  update_ad(params['id'], params['content'])
end

get '/ads/ad/:id/delete' do
  return 406 unless logged_in?
  return 406 unless admin?
  send_file 'views/ads/delete.html'
end

post '/ads/ad/:id/delete' do
  return 406 unless logged_in?
  return 406 unless admin?
  delete_ad(params['id'])
  "deleted ad #{params['id']}"
end

post '/ads/ad/:id/active' do
  return 406 unless logged_in?
  return 406 unless admin?
  ad = Ad.find_by_id params['id']
  return 404 unless ad

  ad.active = !ad.active
  ad.save!
  "ad #{ad.id} active is now set to #{ad.active}"
end

get '/ads/list' do
  return 406 unless logged_in?
  ads = Database.client[:ads].find(:owner => session[:user].email)
  ret = ''
  ads.each do |doc|
    ret = ret + doc.to_s + "<br><form action='/ads/ad/#{doc['id']}/active' method='POST'><button type='submit'>Toggle Active</button></form><form action='/ads/ad/#{doc['id']}/delete' method='POST'><button type='submit'>Delete</button></form>" #display the docs in a nice format :3
  end
  ret
end

get '/ads/new' do
  return 406 unless logged_in?
  return 406 unless admin?
  send_file 'views/ads/new.html'
end

post '/ads/new' do
  return 406 unless logged_in?
  return 406 unless admin?
  return 404 unless params['name'] && params['budget'] && params['content']

  ad = Ad.new(params['name'], params['budget'], params['content'], session[:user].email)
  ad.save!
  return 200
end

post '/groups/new' do
  return 406 unless logged_in?
  return 406 unless admin?
  return 406 unless params['name']

  Group.new(params['name'], session[:user].email).save!
  return 200
end

post '/groups/:group/insert' do
  return 406 unless logged_in?
  return 406 unless admin?
  return 404 unless params['group'] && params['ad']
  ad = Ad.find_by_id params['ad']
  return 404 unless ad
  group = Group.find_by_id params['group']
  return 404 unless group

  insert_ad_to_group group, ad
end

get '/urls/bypass/new' do
  return 406 unless logged_in?
  return 406 unless admin?

  send_file 'views/urls/new.html'
end

post '/urls/bypass/new' do
  return 406 unless logged_in?
  return 406 unless admin?
  return 404 unless params['url']

  url = Url.new params['url']
  url.save!
  url.id
end

get '/urls/redirect/:url' do
  url = Url.find_by_id params['url']
  return 404 unless url
  redirect to(url.url + '?redirect=' + url.id)
end

get '/dashboard' do
  return 406 unless logged_in?
  return 406 unless admin?

  fill_rate = 100 - ((Token.total_unfilled.to_f / Ad.total_impressions.to_f) * 100)

  "total impressions: #{Ad.total_impressions}\n
  total unfilled: #{Token.total_unfilled}\n
  fill rate: #{fill_rate}"
end
