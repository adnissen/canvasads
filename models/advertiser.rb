require_relative 'JSONable'
require_relative '../util'
require_relative '../helpers/application_helper'
require 'bcrypt'


class Advertiser < JSONable

  attr_accessor :username, :email, :password

  def initialize(username='', password='', email='')
    @username = username
    @email = email
    @password = BCrypt::Password.create(password)
  end

  def save!
    if Advertiser.find_by_email @email
      Database.client[:advertisers].find(:email => @email).replace_one(self.to_hash)
    else
      Advertiser.insert_advertiser self
    end
  end

  def log_in!
    log_in_with_password(@email, @password)
  end

  def self.insert_advertiser(advertiser)
    Database.client[:advertisers].insert_one advertiser.to_hash
  end

  def self.find_by_email(email)
    advertiser = Database.client[:advertisers].find(:email => email).first
    if advertiser
      new_advertiser = Advertiser.new
      new_advertiser.from_json! advertiser.to_json
      new_advertiser
    else
      nil
    end
  end
end
