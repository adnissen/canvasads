require 'rspec'
require 'rack/test'
require 'factory_girl'
require_relative '../factories'

describe 'Ad Helper' do
  include Rack::Test::Methods

  it 'should update the budget and inventory of an ad' do
    ad = FactoryGirl.create(:ad)
    update_ad_budget(ad.id, 1.1)
    
    expect(Ad.find_by_id(ad.id).budget).to eq 2.2
    expect(Ad.find_by_id(ad.id).inventory).to eq 2000
  end
end
