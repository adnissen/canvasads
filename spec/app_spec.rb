ENV['RACK_ENV'] = 'test'

require_relative '../app'
require 'rspec'
require 'rack/test'
require 'database_cleaner'

client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => ENV['RACK_ENV'])

describe 'App Routes' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "should create a new user account" do
    get '/advertisers/new', {:username => 'andrew', :password => 'testing', :email => 'andrew_nissen@yahoo.com'}
    expect(last_response).to be_ok
    client[:advertisers].find.count.should == 1

  end

  it 'should log a user in' do
    get '/login', {:password => 'testing', :email => 'andrew_nissen@yahoo.com'}
    expect(last_response).to be_ok
  end

  it 'should create a new ad' do
    get '/login', {:password => 'testing', :email => 'andrew_nissen@yahoo.com'}

    post '/ads/new', {:name => 'test ad', :budget => 200, :content => '<h1>hello!</h1>'}
    expect(last_response).to be_ok
    expect(client[:ads].find.count).to eq 1
  end

  it 'should create a new token' do
    get '/login', {:password => 'testing', :email => 'andrew_nissen@yahoo.com'}

    post '/tokens/new'
    expect(last_response).to be_ok
    expect(client[:tokens].find.count).to eq 1
  end

  it 'should create a group' do
    get '/login', {:password => 'testing', :email => 'andrew_nissen@yahoo.com'}

    post '/groups/new', {:name => 'test group'}
    expect(last_response.status).to eq 200
    expect(client[:groups].find.count).to eq 1
  end

  it 'should add an ad to the group' do
    get '/login', {:password => 'testing', :email => 'andrew_nissen@yahoo.com'}

    group = client[:groups].find.first
    ad = client[:ads].find.first
    post '/groups/' + group['_id'] + '/insert', {:group => group['_id'], :ad => ad['_id']}

    expect(last_response.status).to eq 200
    expect(client[:groups].find.first['ads'].count).to eq 1
  end

  it 'should update token with group' do
    get '/login', {:password => 'testing', :email => 'andrew_nissen@yahoo.com'}
    group = client[:groups].find.first
    token = client[:tokens].find.first
    post '/tokens/' + token['token'] + '/group/update', {:group => group['_id']}
    expect(last_response.status).to eq 200
    expect(client[:tokens].find.first['group']).to eq group['_id']
  end

  it 'should not return an ad' do
    get '/ads'
    expect(last_response.status).to eq 406
  end

  it 'should return an ad' do
    token = client[:tokens].find.first
    get '/ads', {:token => token.token}
    expect(last_response.status).to eq 200
  end

end
