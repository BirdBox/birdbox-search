require 'elasticsearch/persistence/model'
require "birdbox-search/version"
require "birdbox-search/resource"
require "birdbox-search/nest"

# Top-level namespace
module Birdbox

  # An abstraction of the Elasticsearch API powering Birdbox Search.
  module Search
    
    # Sets config
    # @param [block] block
    def Search.configure(config)
      Elasticsearch::Persistence.client = Elasticsearch::Client.new host: config
    end
  
  end
end
