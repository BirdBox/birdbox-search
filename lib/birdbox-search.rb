require "tire"
require "birdbox-search/version"
require "birdbox-search/resource"
require "birdbox-search/nest"

# Top-level namespace
module Birdbox

  # An abstraction of the Elasticsearch API powering Birdbox Search.
  module Search
    
    # Passes configuration attributes to Tire.
    # @param [block] block
    def Search.configure(&block)
      Tire::Configuration.class_eval(&block)
    end
  
  end
end
