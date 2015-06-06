require 'rspec'
require 'rack/test'
require 'factory_girl'
require_relative '../factories'

describe 'Token Model' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it 'should create a new token' do
    token = FactoryGirl.create(:token)
    expect(token).to be
  end

  it 'should save the token' do
    token = FactoryGirl.create(:token)
    expect(token.impressions).to eq 1
    token.impressions += 1
    token.save!
    expect(Token.find_by_token(token.token).impressions).to eq 2
  end

  it 'should find the right token' do
    token = FactoryGirl.create(:token)
    expect(Token.find_by_token(token.token).token).to eq token.token
  end

  it 'should mark when an ad does not fill' do
    token = FactoryGirl.create(:token)

    get '/ads', {:token => token.token}
    expect(last_response.status).to eq 200

    token = Token.find_by_token token.token
    expect(token.unfilled).to eq 1
  end
end
