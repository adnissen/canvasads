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
  return 406 unless log_in(params['email'], params['password'])
  return 200
end

get '/logout' do
  log_out
  'logged out'
end

post '/tokens/new' do
  return 406 unless logged_in?
  return 406 unless admin?
  create_token
end

get '/tokens/:token' do
  return 406 unless logged_in?
  return 405 unless params['token']
  token = Database.client[:tokens].find(:token => params['token']).first
  return 406 unless token && token['owner'] == session[:user]['email']

  token.to_s
end

post '/tokens/:token/group/update' do
  return 406 unless logged_in?
  return 405 unless params['token'] && params['group']
  token = Database.client[:tokens].find(:token => params['token']).first
  return 406 unless token && token['owner'] == session[:user]['email']
  group = Database.client[:groups].find(:_id => params['group']).first
  return 404 unless group

  update_token_group token, group
end

get '/ads' do
  return 406 unless params['token']
  token = Database.client[:tokens].find(:token => params['token']).first
  return 406 unless token

  group = Database.client[:groups].find(:_id => (token['group'] || nil)).first

  ads_array = []

  if !group
    ads = Database.client[:ads].find(:active => true)
    ads.each do |a|
      ads_array << a['_id']
    end
  else
    group['ads'].each do |a|
      ads_array << a
    end
  end
  ads_array.shuffle!
  ad = ads_array.first
  ad = Database.client[:ads].find(:_id => ad).first

  add_impression(ad)
  update_payout(token)

  ad['content']
end

get '/ads/ad/:_id' do
  ad = Database.client[:ads].find(:_id => params['_id']).first
  return 'ad not found' unless ad
  add_impression(ad)
  ad['content']
end

get '/ads/ad/:_id/update' do
  return 406 unless logged_in?
  return 406 unless admin?
  send_file 'views/ads/update.html'
end

post '/ads/ad/:_id/update' do
  return 406 unless logged_in?
  return 406 unless admin?
  return 406 unless params['content']
  update_ad(params['_id'], params['content'])
end

get '/ads/ad/:_id/delete' do
  return 406 unless logged_in?
  return 406 unless admin?
  send_file 'views/ads/delete.html'
end

post '/ads/ad/:_id/delete' do
  return 406 unless logged_in?
  return 406 unless admin?
  delete_ad(params['_id'])
end

get '/ads/list' do
  return 406 unless logged_in?
  ads = Database.client[:ads].find(:owner => session[:user]['email'])
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
  create_ad(params['name'], params['budget'], params['content'], 123124124124)
end

post '/groups/new' do
  return 406 unless logged_in?
  return 406 unless admin?
  return 406 unless params['name']

  create_group params['name']
end

post '/groups/:group/insert' do
  return 406 unless logged_in?
  return 406 unless admin?
  return 404 unless params['group'] && params['ad']
  ad = Database.client[:ads].find(:_id => params['ad']).first
  return 404 unless ad
  group = Database.client[:groups].find(:_id => params['group']).first
  return 404 unless group

  insert_ad_to_group group, ad
end
