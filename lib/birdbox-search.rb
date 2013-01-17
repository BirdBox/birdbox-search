require "tire"
require "birdbox-search/version"
require "birdbox-search/resource"
require "birdbox-search/nest"

module Birdbox
  module Search
    
    def Search.configure(&block)
      Tire::Configuration.class_eval(&block)
    end
  
  end
end
