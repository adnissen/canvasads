require_relative 'JSONable'
require_relative '../util'

class Ad < JSONable
  attr_accessor :id, :name, :budget, :content, :owner, :active, :impressions, :inventory
  def initialize(name='', budget=0, content='', owner='')
    @name = name
    @budget = budget
    @content = content
    @owner = owner

    @id = (0...8).map { (65 + rand(26)).chr }.join
    @active = false
    @inventory = (budget.to_f / 1.10) * 1000
    @impressions =  0
  end

  def update_content(content)
    @content = content
    Database.client[:ads].find(:id => @id).update_one("$set" => { :content => content })
  end

  def delete!
    Ad.delete_by_id @id
  end

  def save!
    if Ad.find_by_id @id
      Database.client[:ads].find(:id => @id).replace_one(self.to_hash)
    else
      Ad.insert_ad self
    end
  end

  def add_impression
    @impressions += 1
    @inventory -= 1
    if @inventory <= 0
      @active = false
    end
    self.save!
  end

  def self.insert_ad(ad)
    Database.client[:ads].insert_one ad.to_hash
  end

  def self.find_by_id(id)
    ad = Database.client[:ads].find(:id => id).first
    if ad
      new_ad = Ad.new
      new_ad.from_json! ad.to_json
      new_ad
    else
      nil
    end
  end

  def self.delete_by_id(id)
    Database.client[:ads].find(:id => id).delete_one
  end

  def self.total_impressions
    ads = Database.client[:ads].find
    total = 0
    ads.each do |ad|
      total += (ad['impressions'] || 0)
    end
    total
  end
end
