require 'net/http'
require 'yaml'

# Front for RubyGems
class SourceUnavailableError < StandardError; end
class RubyGems
  attr_reader :uri
  
  def data(name)
    YAML.load(self.get("/api/v1/gems/#{name}.yaml"))
  end

  def initialize(uri)
    @connection = nil
    @uri = uri.kind_of?(URI::Generic) ? uri : URI(uri.to_s)
  end
  
  # May raise SourceUnavailableError if the source can't be accessed
  def get(path, data={}, content_type='application/x-www-form-urlencoded')
    begin
      request = Net::HTTP::Get.new(path)
      request.add_field 'Connection', 'keep-alive'
      request.add_field 'Keep-Alive', '30'
      request.add_field 'User-Agent', 'github.com/jonathannen/gemfresh'
      response = connection.request request
      response.body  
    rescue StandardError => se
      # For now we assume this is an unavailable repo
      raise SourceUnavailableError.new(se.message)
    end
  end

  # @param [ String ] name The name of the gem to access.
  #
  # @return [ Hash ] version data for the given named gem
  def versions(name)
    YAML.load(self.get("/api/v1/versions/#{name}.yaml"))
  end

  private
  # A persistent connection
  def connection
    return @connection unless @connection.nil?
    @connection = Net::HTTP.new self.uri.host, self.uri.port
    @connection.use_ssl = (uri.scheme == 'https')
    @connection.start 
    @connection
  end
end
