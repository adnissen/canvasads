require 'rspec'
require 'rack/test'
require 'factory_girl'
require_relative '../factories'

describe 'Group Model' do
  include Rack::Test::Methods

  it 'should find a group by id' do
    group = FactoryGirl.create(:group)
    expect(Group.find_by_id(group.id).name).to eq group.name
  end

  it 'should save a group' do
    group = FactoryGirl.create(:group)
    group.name = 'testing testing testing'
    group.save!

    expect(Group.find_by_id(group.id).name).to eq group.name
  end
end
