require 'sinatra'
require 'mongo'
require 'pry'
require_relative 'helpers/ads_helper'
require_relative 'helpers/advertiser_helper'
require_relative 'helpers/application_helper'
require_relative 'helpers/token_helper'
require_relative 'helpers/group_helper'


enable :sessions
set :session_secret, 'adsfkljadsufljsadlft'
set :protection, :except => :frame_options

client = Mongo::Client.new(ENV['MONGOLAB_URI'] || [ '127.0.0.1:27017' ], :database => ENV['RACK_ENV'] || 'heroku_app37387124')

get '/' do
  "Canvas, advertising done right."
end

get '/advertisers/new' do
  return 406 unless params['username'] && params['password'] && params['email']
  create_advertiser(client, params['username'], params['password'], params['email'])
end

get '/login' do
  return 406 unless log_in(client, params['email'], params['password'])
  return 200
end

get '/logout' do
  log_out
  'logged out'
end

post '/tokens/new' do
  return 406 unless logged_in?
  return 406 unless admin?
  create_token client
end

get '/tokens/:token' do
  return 406 unless logged_in?
  return 405 unless params['token']
  token = client[:tokens].find(:token => params['token']).first
  return 406 unless token && token['owner'] == session[:user]['email']

  token.to_s
end

post '/tokens/:token/group/update' do
  return 406 unless logged_in?
  return 405 unless params['token'] && params['group']
  token = client[:tokens].find(:token => params['token']).first
  return 406 unless token && token['owner'] == session[:user]['email']
  group = client[:groups].find(:_id => params['group']).first
  return 404 unless group

  update_token_group client, token, group
end

get '/ads' do
  return 406 unless params['token']
  token = client[:tokens].find(:token => params['token']).first
  return 406 unless token

  group = client[:groups].find(:_id => (token['group'] || nil)).first

  ads_array = []

  if !group
    ads = client[:ads].find(:active => true)
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
  ad = client[:ads].find(:_id => ad).first

  add_impression(ad, client)
  update_payout(token, client)

  ad['content']
end

get '/ads/ad/:_id' do
  ad = client[:ads].find(:_id => params['_id']).first
  return 'ad not found' unless ad
  add_impression(ad, client)
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
  update_ad(client, params['_id'], params['content'])
end

get '/ads/ad/:_id/delete' do
  return 406 unless logged_in?
  return 406 unless admin?
  send_file 'views/ads/delete.html'
end

post '/ads/ad/:_id/delete' do
  return 406 unless logged_in?
  return 406 unless admin?
  delete_ad(client, params['_id'])
end

get '/ads/list' do
  return 406 unless logged_in?
  ads = client[:ads].find(:owner => session[:user]['email'])
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
  create_ad(client, params['name'], params['budget'], params['content'], 123124124124)
end

post '/groups/new' do
  return 406 unless logged_in?
  return 406 unless admin?
  return 406 unless params['name']

  create_group client, params['name']
end

post '/groups/:group/insert' do
  return 406 unless logged_in?
  return 406 unless admin?
  return 404 unless params['group'] && params['ad']
  ad = client[:ads].find(:_id => params['ad']).first
  return 404 unless ad
  group = client[:groups].find(:_id => params['group']).first
  return 404 unless group

  insert_ad_to_group client, group, ad
end
