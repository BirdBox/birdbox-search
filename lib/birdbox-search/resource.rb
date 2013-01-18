module Birdbox
  module Search

    # A module encapsulating the properties and mappings of the `resources` index.
    module Searchable
      # Set the index properties and mappings of the class including this module.
      def self.included(base)
        base.class_eval do
          index_prefix ""
          index_name "resources"
          document_type "resource"

          mapping do
              property :provider,         :type => 'string',  :index => 'not_analyzed'
              property :external_id,      :type => 'string',  :index => 'not_analyzed'
              property :owner_uid,        :type => 'string',  :index => 'not_analyzed'
              property :owner_nickname,   :type => 'string',  :index => 'not_analyzed'
              property :title,            :type => 'string',  :index => 'analyzed',     :analyzer => 'standard'
              property :url,              :type => 'string',  :index => 'not_analyzed'
              property :type,             :type => 'string',  :index => 'not_analyzed'
              property :tags,             :type => 'string',  :index => 'analyzed',     :analyzer => 'keyword', :default => [ ]
              property :height,           :type => 'integer', :index => 'no'
              property :width,            :type => 'integer', :index => 'no'
              property :created_at,      :type => 'date',    :index => 'not_analyzed'
              property :taken_at,         :type => 'date',    :index => 'not_analyzed'
              property :description,      :type => 'string',  :index => 'analyzed',     :analyzer => 'standard'
              property :download_url,     :type => 'string',  :index => 'no'
              property :thumbnail_url,    :type => 'string',  :index => 'no'
              property :thumbnail_height, :type => 'integer', :index => 'no'
              property :thumbnail_width,  :type => 'integer', :index => 'no'
              property :html,             :type => 'string',  :index => 'no'
              property :owned,            :type => 'boolean', :index => 'not_analyzed'
            end
        end
      end
    end

    # The Resource class wraps an Elasticsearch index by the same name. Note that the 
    # mappings are only applied when calling Resource.create_elasticsearch_index.
    # Using Resource.index.create will create a generic index with no mappings.
    class Resource
      include Tire::Model::Persistence
      include Tire::Model::Search
      include Tire::Model::Callbacks
      include Birdbox::Search::Searchable

      OPTIMUM_THUMBNAIL_WIDTH = 220

      # Parses hashtags from the resource's title and description attribute.
      def parse_hashtags
        hashtags = self.title.to_s.downcase.scan(/\B#\w+/).uniq.each do |h|
          h.gsub!('#', '').strip!
        end
        hashtags += self.description.to_s.downcase.scan(/\B#\w+/).uniq.each do |h|
          h.gsub!('#', '').strip!
        end
        if self.tags
          self.tags.concat hashtags.uniq
          self.tags = self.tags.uniq
        else
          self.tags = hashtags.uniq
        end
      end

      # Only saves a resource if it does not already exist or if its tags have
      # been modified. Updating a search index is an expensive operation and
      # since we are constantly rescanning resources, this method should help
      # migigate the impact on search performance.
      #
      # @return [Integer] 1 if the document was updated or 0 if it was not
      def persist
        ret = 0
        self.id = "#{self.provider}:#{self.external_id}"
        resource = Resource.find(self.id)
        if !resource or resource.tags != self.tags
          self.save
          ret = 1
        end
        ret
      end
      
    end

  end
end
