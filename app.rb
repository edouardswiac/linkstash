#require 'rack/conneg'
require 'sinatra'
require 'redis'
require 'haml'
require 'json'
require 'uri'

require './lib/stash.rb'

# configure
configure :production do
  set :haml, { :ugly=>true }
  set :clean_trace, true
end

configure :development do
end

uri = URI.parse(ENV["REDISTOGO_URL"])
REDIS =  Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

# helpers
helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

# routes
## main /
get "/" do
  @title = "Linkstash.net"
  haml :main
end

post "/" do
  @stash = Stash.create
  redirect "/#{@stash.id}"
end

## stash /:stash_id
get "/:stash_id" do
  id = params[:stash_id]
  pass unless Stash.exists? id 
  @stash = Stash.new(id)
  haml :stash
end

post "/:stash_id" do
  id = params[:stash_id]
  pass unless Stash.exists? id 
  Stash.new(id).add_url(params[:url])
end
