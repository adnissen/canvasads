require 'rspec'
require 'rack/test'
require 'factory_girl'
require_relative '../factories'

describe 'Advertiser Model' do
  include Rack::Test::Methods

  it 'should find an advertiser by email' do
    user = FactoryGirl.create(:advertiser)
    expect(Advertiser.find_by_email(user.email).email).to eq user.email
  end

  it 'should find an advertiser by username' do
    user = FactoryGirl.create(:advertiser)
    expect(Advertiser.find_by_username(user.username).username).to eq user.username
  end

  it 'should save an advertiser' do
    user = FactoryGirl.create(:advertiser)
    user.email = 'new@mail.com'
    user.save!

    expect(Advertiser.find_by_email('new@mail.com').email).to eq user.email
  end
end
