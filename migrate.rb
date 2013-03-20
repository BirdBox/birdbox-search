require 'tire'
require './lib/birdbox-search/version'
require './lib/birdbox-search/resource'

Tire.configure do
  url 'http://localhost:9200'
  #logger STDERR, :debug => true
end

search = Tire.search('resources') do
  query { all }
end

resources = search.results.map { |r|
  resource = Birdbox::Search::Resource.new(r.to_hash)
  resource.albums = [resource.album]
  resource
}

Tire.index 'resources_v1' do
  import resources
end
