require 'rspec'
require 'rack/test'

describe 'Ad Model' do
  include Rack::Test::Methods

  it 'should create a new ad' do
    @ad = Ad.new 'test', 200, 'hi!', 'andrew_nissen@yahoo.com'
    expect(@ad).to be
    expect(@ad.owner).to eq 'andrew_nissen@yahoo.com'
    expect(@ad.content).to eq 'hi!'
  end

  it 'should insert a new ad' do
    @ad = Ad.new 'test', 200, 'hi!', 'andrew_nissen@yahoo.com'
    Ad.insert_ad @ad
    expect(Database.client[:ads].find.count).to eq 1
  end

  it 'should find the right ad' do
    @ad = Ad.new 'test', 200, 'hi!', 'andrew_nissen@yahoo.com'
    Ad.insert_ad @ad
    expect((Ad.find_by_id @ad.id).id).to eq @ad.id
  end
end
