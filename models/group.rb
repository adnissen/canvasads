require_relative 'JSONable'
require_relative '../util'
require_relative '../helpers/application_helper'
require 'bcrypt'


class Group < JSONable

  attr_accessor :ads, :name, :owner, :id

  def initialize(name='', owner='')
    @ads = Array.new
    @name = name
    @owner = owner
    @id = (0...16).map { (65 + rand(26)).chr }.join
  end

  def save!
    if Group.find_by_id @id
      Database.client[:groups].find(:id => @id).replace_one(self.to_hash)
    else
      Group.insert_group self
    end
  end

  def self.insert_group(group)
    Database.client[:groups].insert_one group.to_hash
  end

  def self.find_by_id(id)
    group = Database.client[:groups].find(:id => id).first
    if group
      new_group = Group.new
      new_group.from_json! group.to_json
      new_group
    else
      nil
    end
  end

  def active_ads
    ret = []
    @ads.each do |ad|
      ad = Ad.find_by_id(ad)
      ret << ad if ad.active
    end
  end

end
