require 'rest-client'
require 'securerandom'
require 'nokogiri'   

class Stash

  attr_reader :id, :urls

  def initialize id
    raise "This stash does not exist" unless Stash.exists? id
    @id = id
    @key = "stash:#{@id}"
    @key_urls = @key+":urls"
    #logger.info "Initializing stash##{id} from redis key #{@redis_key}"
    @urls =  load_urls
  end

  def add_url url
    puts "Adding URL #{url} to the stash"
    url = URI.escape(url)

    begin
      title = Stash.get_title_from_html(RestClient.get(url))
    rescue => e
      puts e
      raise "Cannot resolve URL"
    end

    @url_obj = {:url => url, :title => title, :created => Time.new}
    REDIS.lpush(@key_urls, @url_obj.to_json)
  end

  def load_urls
    llen = REDIS.llen(@key_urls) || 0
    return [] if llen == 0
    REDIS.lrange(@key_urls, 0, llen-1).map {|u| JSON.parse(u, {:symbolize_names => true})}
  end

  def self.exists?(id)
    puts "Lookup stash:#{id}"
    REDIS.exists "stash:#{id}"
  end

  def self.create
    id = "-"
    while id.match /[-_]/
      id = SecureRandom.urlsafe_base64(6)
    end
    urls = {}
    REDIS.set("stash:#{id}", id)
    return Stash.new(id)
  end

  def self.get_title_from_html(html)
    frag = Nokogiri::HTML::Document.parse(html)
    return frag.title
  end

end
