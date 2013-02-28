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
            # user has many authentication which has many services, so if we EVER want to tie the resource to a service, unfortunately
            # we have to persist the service somehow (and do not want to couple these togther) - so add a service name
            # think of google as the authentication provider and 'picasa, g+, gmail, etc as the services'
            property :service,                :type => 'string',  :index => 'not_analyzed'
            property :provider,               :type => 'string',  :index => 'not_analyzed'
            property :external_id,            :type => 'string',  :index => 'not_analyzed'
            property :owner_uid,              :type => 'string',  :index => 'not_analyzed'
            property :owner_nickname,         :type => 'string',  :index => 'not_analyzed'
            property :owner_birdbox_nickname, :type => 'string',  :index => 'not_analyzed'
            property :owner_avatar,           :type => 'string',  :index => 'not_analyzed'
            property :album,                  :type => 'string',  :index => 'not_analyzed'
            property :title,                  :type => 'string',  :index => 'analyzed',     :analyzer => 'standard'
            property :url,                    :type => 'string',  :index => 'not_analyzed'
            property :type,                   :type => 'string',  :index => 'not_analyzed'
            property :tags,                   :type => 'string',  :index => 'not_analyzed', :default => [ ]
            # property :people,                 :type => 'string',  :index => 'not_analyzed', :default => [ ]
            
            property :people,                  :type => 'object',
              :properties => {
                :id => {:type => "string", :index => :not_analyzed },
                :name => { :type => "string", :index => :not_analyzed }
              }

            property :height,                 :type => 'integer', :index => 'no'
            property :width,                  :type => 'integer', :index => 'no'
            property :created_at,             :type => 'date',    :index => 'not_analyzed'
            property :updated_at,             :type => 'date',    :index => 'not_analyzed'
            property :uploaded_at,            :type => 'date',    :index => 'not_analyzed'
            property :taken_at,               :type => 'date',    :index => 'not_analyzed'
            property :description,            :type => 'string',  :index => 'analyzed',     :analyzer => 'standard'
            property :download_url,           :type => 'string',  :index => 'no'
            property :thumbnail_url_small,    :type => 'string',  :index => 'no'
            property :thumbnail_height_small, :type => 'integer', :index => 'no'
            property :thumbnail_width_small,  :type => 'integer', :index => 'no'
            property :thumbnail_url_medium,   :type => 'string',  :index => 'no'
            property :thumbnail_height_medium,:type => 'integer', :index => 'no'
            property :thumbnail_width_medium, :type => 'integer', :index => 'no'
            property :thumbnail_url_large,    :type => 'string',  :index => 'no'
            property :thumbnail_height_large, :type => 'integer', :index => 'no'
            property :thumbnail_width_large,  :type => 'integer', :index => 'no'
            property :html,                   :type => 'string',  :index => 'no'
            property :owned,                  :type => 'boolean', :index => 'not_analyzed'
            property :active,                 :type => 'boolean', :index => 'not_analyzed'
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

      before_save :before_save
      after_save :after_save

      # When a 3rd party (such as facebook) yields multiple thumbnails pick the one that is closest (larger preferred) to the desired width
      OPTIMUM_THUMBNAIL_WIDTH_SMALL = 70
      OPTIMUM_THUMBNAIL_WIDTH_MEDIUM = 270
      OPTIMUM_THUMBNAIL_WIDTH_LARGE = 370


      # Looks up a user's existing tags and returns a unique list (including 
      # the number of times the tag was found, sorted alphabetically.
      #
      # @param [String] uid the user's id
      # @return [Array] a list of tags and the associated count
      #
      def self.find_unique_user_tags(uid)
        Resource.search {
          query { string "owner_uid:#{uid}" }
          facet('tags') { terms :tags, order: 'term' }
        }.facets['tags']['terms'].map do |f|
          [f['term'], f['count']]
        end
      end


      # Looks up a user's existing tags and returns a unique list (including 
      # the number of times the tag was found, sorted alphabetically.
      #
      # @param [String] uid the user's id
      # @return [Array] a list of tags and the associated count
      #
      def self.find_unique_user_tags(uid)
        Resource.search {
          query { string "owner_uid:#{uid}" }
          facet('tags') { terms :tags, order: 'term' }
        }.facets['tags']['terms'].map do |f|
          [f['term'], f['count']]
        end
      end

      # Default constructor
      def initialize(params={})
        @_updated = false
        self.tags = []
        self.people = []
        self.active = true
        super(params)
      end

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

      #
      def updated?
        return @_updated
      end


      private

      # Only saves a resource if it does not already exist or if its tags or people tagged
      # have been modified. Updating a search index is an expensive operation and
      # since we are constantly rescanning resources, this method should help
      # migigate the impact on search performance.
      def before_save
        self.id = "#{self.provider}:#{self.external_id}"
        @_updated = false
        resource = Resource.find(self.id)
        if resource and resource.tags == self.tags and resource.people == self.people
          return false
        end
        self.created_at = (self.created_at || Time.now).utc
        self.updated_at = Time.now.utc
        true
      end


      # Set the @_updated flag to signal that the save operation caused
      # the index to be updated.
      def after_save
        @_updated = true
      end

    end

  end
end
