require "sinatra"
require "mongo"
require "pry"
require "json"
require "keen"
require 'newrelic_rpm' if ENV['NEW_RELIC_APP_NAME']
require_relative 'helpers/ads_helper'
require_relative 'helpers/advertiser_helper'
require_relative 'helpers/application_helper'
require_relative 'helpers/token_helper'
require_relative 'helpers/group_helper'
require_relative 'helpers/ad_fetcher'
require_relative 'models/ad'
require_relative 'models/JSONable'
require_relative 'models/token'
require_relative 'models/advertiser'
require_relative 'models/group'
require_relative 'models/url'
require_relative 'util'

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
  return 406 unless !session[:last_seen_ad].nil?
  ad = Ad.find_by_id session[:last_seen_ad]
  return 404 unless ad

  ad.engagements += 1
  ad.save!

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
  return 406 unless params['token']
  token = Token.find_by_token params['token']
  return 406 unless token

  group = Group.find_by_id token.group

  ads_array = []

  if !group
    ad = ad_fetcher
  else
    ad = ad_fetcher_by_group group
  end

  if ad
    ad.add_impression
    update_payout(token)

    # this needs to be converted into a class!!
    impression = {}
    impression[:ad] = ad.id
    impression[:token] = token.token
    if group
      impression[:group] = group.id
    else
      impression[:group] = nil
    end
    impression[:time] = Date.today
    impression[:ip] = request.ip

    Keen.publish(:ad_views, impression) if ENV["KEEN_PROJECT_ID"]

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
