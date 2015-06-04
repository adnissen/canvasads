require 'rspec'
require 'rack/test'
require 'factory_girl'
require_relative '../factories'

describe 'Ad Model' do
  include Rack::Test::Methods

  it 'should create a new ad' do
    ad = FactoryGirl.build(:ad)
    expect(ad).to be
    expect(ad.owner).to eq 'andrew_nissen@yahoo.com'
    expect(ad.content).to eq 'hi!'
  end

  it 'should insert a new ad' do
    ad = FactoryGirl.build(:ad)
    Ad.insert_ad ad
    expect(Database.client[:ads].find.count).to eq 1
  end

  it 'should find the right ad' do
    ad = FactoryGirl.build(:ad)
    Ad.insert_ad ad
    expect((Ad.find_by_id ad.id).id).to eq ad.id
  end

  it 'should update the ad content' do
    ad = FactoryGirl.build(:ad)
    Ad.insert_ad ad
    expect((Ad.find_by_id ad.id).content).to eq ad.content
    ad.update_content 'bye!'
    expect((Ad.find_by_id ad.id).content).to eq ad.content
  end

  it 'should delete the ad' do
    ad = FactoryGirl.build(:ad)
    Ad.insert_ad ad
    expect(Database.client[:ads].find.count).to eq 1
    ad.delete!
    expect(Database.client[:ads].find.count).to eq 0
  end

  it 'should save the ad' do
    ad = FactoryGirl.build(:ad)
    ad.name = 'new name'
    ad.save!
    expect((Ad.find_by_id ad.id).name).to eq ad.name
  end
end
