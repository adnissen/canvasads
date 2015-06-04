require_relative 'JSONable'
require_relative '../util'

class Ad < JSONable
  def initialize(name, budget, content, owner)
    @name = name
    @budget = budget
    @content = content
    @owner = owner

    @_id = (0...8).map { (65 + rand(26)).chr }.join
    @active = false
    @inventory = (budget.to_i / 1.50) * 1000
  end

  def update_content(content)
    Database.client[:ads].find(:_id => @_id).update_one("$set" => { :content => content })
  end

  def owner
    @owner
  end

  def content
    @content
  end

  def add_impression
    Database.client[:ads].find(:_id => @id).update_one("$inc" => { :inventory => -1 })
    Database.client[:ads].find(:_id => @id).update_one("$inc" => { :impressions => 1 })
  end

  def self.insert_ad(ad)
    Database.client[:ads].insert_one ad.to_hash
  end

  def self.find_by_id(id)
    ad = Database.client[:ads].find(:_id => id).first
    Ad.new ad['name'], ad['budget'], ad['content'], ad['owner']
  end

  def self.delete_by_id(id)
    Database.client[:ads].find(:_id => id).delete_one
  end
end
