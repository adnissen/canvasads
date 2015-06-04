module Database
  @client = Mongo::Client.new(ENV['MONGOLAB_URI'] || [ '127.0.0.1:27017' ], :database => ENV['RACK_ENV'] || 'heroku_app37387124')

  def self.client
    @client
  end
end
