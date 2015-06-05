require_relative 'JSONable'
require_relative '../util'

class Url < JSONable

  attr_accessor :url, :id

  def initialize(url='')
    @url = url
    @id = (0...8).map { (65 + rand(26)).chr }.join
  end

  def save!
    if Url.find_by_id @id
      Database.client[:urls].find(:id => @id).replace_one(self.to_hash)
    else
      Url.insert_url self
    end
  end

  def self.find_by_id(id)
    url = Database.client[:urls].find(:id => id).first
    if url
      new_url = Url.new
      new_url.from_json! url.to_json
      new_url
    else
      nil
    end
  end

  def self.insert_url(url)
    Database.client[:urls].insert_one url.to_hash
  end
end
