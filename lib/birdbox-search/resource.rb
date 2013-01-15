module Birdbox
  module Search

    class Resource
      include Tire::Model::Persistence

      index_prefix ""
      index_name "resources"

      property :title,   :type => 'string', :analyzer => 'snowball'
      property :url,     :type => 'string', :index => 'not_indexed' 
      property :type,    :type => 'string', :analyzer => 'keyword'
      property :tags,    :default => [ ], :index => 'keyword'
      #property :height, :type => 'number', :index => 'not_indexed'
      #property :width,  :type => 'number', :index => 'not_indexed'

    end

  end
end
