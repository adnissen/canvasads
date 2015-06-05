require 'sinatra'
require 'mongo'
require 'pry'
require 'json'
require_relative 'helpers/ads_helper'
require_relative 'helpers/advertiser_helper'
require_relative 'helpers/application_helper'
require_relative 'helpers/token_helper'
require_relative 'helpers/group_helper'
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

get '/' do
  send_file "index.html"
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
    ads = Database.client[:ads].find(:active => true)
    ads.each do |a|
      ads_array << a['id']
    end
  else
    group.ads.each do |a|
      ads_array << a
    end
  end
  ads_array.shuffle!
  ad = ads_array.first
  ad = Ad.find_by_id ad

  ad.add_impression
  update_payout(token)

  ad.content
end

get '/ads/ad/:id' do
  ad = Database.client[:ads].find(:id => params['id']).first
  return 'ad not found' unless ad
  add_impression(ad)
  ad['content']
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
end

get '/ads/list' do
  return 406 unless logged_in?
  ads = Database.client[:ads].find(:owner => session[:user].email)
  ret = ''
  ads.each do |doc|
    ret = ret + doc.to_s + '<br>' #display the docs in a nice format :3
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

  ad = Ad.new(params['name'], params['budget'], params['content'])
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

post '/urls/bypass/new' do
  return 406 unless logged_in?
  return 406 unless admin?
  return 404 unless params['url']

  url = Url.new params['url']
  url.save!
  url.id
end

get '/urls/bypass/:url' do
  url = Url.find_by_id params['url']
  return 404 unless url
  redirect to(url.url + '?redirect=' + url.id)
end
