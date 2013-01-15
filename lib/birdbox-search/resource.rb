module Birdbox
  module Search

    class Resource
      include Tire::Model::Persistence

      index_prefix ""
      index_name "resources"

      validates_presence_of :source, :owner, :type, :url
      #validates_format_of :height, :allow_nil => true, :with => /\d+/
      #validates_format_of :width, :allow_nil => true, :with => /\d+/

      property :source,     :type => 'string', :analyzer => 'keyword'
      property :owner,      :type => 'string', :analyzer => 'keyword'
      property :title,      :type => 'string', :analyzer => 'snowball'
      property :url,        :type => 'string', :index => 'not_indexed' 
      property :type,       :type => 'string', :analyzer => 'keyword'
      property :tags,       :default => [ ], :index => 'keyword'
      property :height,     :type => 'integer', :index => 'not_indexed'
      property :width,      :type => 'integer', :index => 'not_indexed'
      property :created_at, :type => 'date'

    end

  end
end
