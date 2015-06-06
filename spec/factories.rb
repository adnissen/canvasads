require 'bcrypt'
FactoryGirl.define do

  factory :ad do
    name 'test'
    budget 1.10
    content 'hi!'
    owner 'andrew_nissen@yahoo.com'
    inventory 1000
  end

  factory :token do
    owner 'andrew_nissen@yahoo.com'
  end

  factory :advertiser do
    username 'test'
    password BCrypt::Password.create('secret')
    email 'andrew_nissen@yahoo.com'
  end

  factory :group do
    name 'test group'
  end

  factory :url do
  end

end
