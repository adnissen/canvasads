require 'rspec'
require 'rack/test'
require 'factory_girl'
require_relative '../factories'

describe 'Token Model' do
  it 'should create a new token' do
    token = FactoryGirl.create(:token)
    expect(token).to be
  end

  it 'should save the token' do
    token = FactoryGirl.create(:token)
    expect(token.impressions).to eq 0
    token.impressions += 1
    token.save!
    expect(Token.find_by_token(token.token).impressions).to eq 1
  end

  it 'should find the right token' do
    token = FactoryGirl.create(:token)
    expect(Token.find_by_token(token.token).token).to eq token.token
  end
end
