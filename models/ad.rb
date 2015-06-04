require_relative 'JSONable'

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
    @client[:ads].find(:_id => @_id).update_one("$set" => { :content => content })
  end

  def owner
    @owner
  end

  def add_impression
    @client[:ads].find(:_id => @id).update_one("$inc" => { :inventory => -1 })
    @client[:ads].find(:_id => @id).update_one("$inc" => { :impressions => 1 })
  end

  public

  def find_by_id(id)
    ad = @client[:ads].find(:_id => _id)
    Ad.new ad['name'], ad['budget'], ad['content'], ad['owner']
  end

  def delete_by_id(id)
    @client[:ads].find(:_id => id).delete_one
  end
end
