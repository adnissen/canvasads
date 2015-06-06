ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require 'factory_girl'
require_relative '../app'
require_relative 'factories'

describe 'App Routes' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "should create a new user account" do
    get '/advertisers/new', {:username => 'andrew', :password => 'testing', :email => 'andrew_nissen@yahoo.com'}
    expect(last_response).to be_ok
    Database.client[:advertisers].find.count.should == 1
  end

  it 'should log a user in' do
    FactoryGirl.build(:advertiser).save!
    get '/login', {:email => 'andrew_nissen@yahoo.com', :password => 'secret'}
    expect(last_response).to be_ok
  end

  it 'should create a new ad' do
    user = FactoryGirl.create(:advertiser)
    get '/login', {:email => 'andrew_nissen@yahoo.com', :password => 'secret'}

    post '/ads/new', {:name => 'test ad', :budget => 200, :content => '<h1>hello!</h1>'}
    expect(last_response).to be_ok
    expect(Database.client[:ads].find.count).to eq 1
  end

  it 'should create a new token' do
    user = FactoryGirl.create(:advertiser)
    get '/login', {:email => 'andrew_nissen@yahoo.com', :password => 'secret'}

    post '/tokens/new'
    expect(last_response).to be_ok
    expect(Database.client[:tokens].find.count).to eq 1
  end

  it 'should create a group' do
    user = FactoryGirl.create(:advertiser)
    get '/login', {:email => 'andrew_nissen@yahoo.com', :password => 'secret'}

    post '/groups/new', {:name => 'test group'}
    expect(last_response.status).to eq 200
    expect(Database.client[:groups].find.count).to eq 1
  end

  it 'should add an ad to the group' do
    user = FactoryGirl.create(:advertiser)
    get '/login', {:email => 'andrew_nissen@yahoo.com', :password => 'secret'}

    group = FactoryGirl.create(:group)
    ad = FactoryGirl.create(:ad)
    post '/groups/' + group.id + '/insert', {:group => group.id, :ad => ad.id}

    expect(last_response.status).to eq 200
    expect(Group.find_by_id(group.id).ads.count).to eq 1
  end

  it 'should update token with group' do
    user = FactoryGirl.create(:advertiser)
    get '/login', {:email => 'andrew_nissen@yahoo.com', :password => 'secret'}
    group = FactoryGirl.create(:group)
    token = FactoryGirl.create(:token)
    post '/tokens/'   + token.token + '/group/update', {:group => group.id}
    expect(last_response.status).to eq 200
    expect(Token.find_by_token(token.token).group).to eq group.id
  end

  it 'should not return an ad' do
    get '/ads'
    expect(last_response.status).to eq 406
  end

  it 'should return an ad' do
    token = FactoryGirl.create(:token)
    ad = FactoryGirl.create(:ad)
    ad.active = true
    ad.save!
    group = FactoryGirl.create(:group)

    get '/ads', {:token => token.token}
    expect(last_response.status).to eq 200
    expect(last_response.body).not_to eq 'nil'
  end

  it 'should return the token information' do
    token = FactoryGirl.create(:token)
    ad = FactoryGirl.create(:ad)
    user = FactoryGirl.create(:advertiser)
    get '/login', {:email => 'andrew_nissen@yahoo.com', :password => 'secret'}

    get '/tokens/' + token.token
    expect(last_response.status).to eq 200
    expect(last_response.body).not_to eq "nil"
  end

  it 'should generate a bypass url' do
    token = FactoryGirl.create(:token)
    user = FactoryGirl.create(:advertiser)
    get '/login', {:email => 'andrew_nissen@yahoo.com', :password => 'secret'}

    post '/urls/bypass/new', {:url => '/tokens/' + token.token}
    expect(last_response.status).to eq 200
  end

  it 'should redirect the user to the new url' do
    url = FactoryGirl.create(:url)
    token = FactoryGirl.create(:token)
    url.url = "/tokens/#{token.token}"
    url.save!

    get "/urls/redirect/#{url.id}"
    expect(last_response.status).to eq 302
    expect(last_response.header['Location']).to eq "http://example.org#{url.url}?redirect=#{url.id}"

    get "#{url.url}", {:redirect => url.id}
    expect(last_response.status).to eq 200
  end

  it 'should load the dashboard' do
    user = FactoryGirl.create(:advertiser)
    get '/login', {:email => 'andrew_nissen@yahoo.com', :password => 'secret'}
    ad = FactoryGirl.create(:ad)
    token = FactoryGirl.create(:token)
    ad.add_impression

    get '/dashboard'
    expect(last_response.status).to eq 200
  end

end
