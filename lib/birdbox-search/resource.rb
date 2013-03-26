require 'digest/md5'

module Birdbox
  module Search

    # The Resource class wraps an Elasticsearch index by the same name. Note that the 
    # mappings are only applied when calling Resource.create_elasticsearch_index.
    # Using Resource.index.create will create a generic index with no mappings.
    class Resource
      attr_accessor :remove_albums
      attr_accessor :new_albums
      include Tire::Model::Persistence

      # A class method defining the properties and mappings of the `resources` index.
      def self.create_mappings
        index_prefix ""
        index_name "resources_v1"
        document_type "resource"
        mapping do
          # user has many authentication which has many services, so if we EVER want to tie the resource to a service, unfortunately
          # we have to persist the service somehow (and do not want to couple these togther) - so add a service name
          # think of google as the authentication provider and 'picasa, g+, gmail, etc as the services'
          property :service,                :type => 'string',  :index => 'not_analyzed'
          property :provider,               :type => 'string',  :index => 'not_analyzed'
          property :external_id,            :type => 'string',  :index => 'not_analyzed'
          property :owner_uid,              :type => 'string',  :index => 'not_analyzed'
          property :owner_birdbox_nickname, :type => 'string',  :index => 'not_analyzed'
          property :owner_avatar,           :type => 'string',  :index => 'not_analyzed'
          property :source_uid,             :type => 'string',  :index => 'not_analyzed'
          property :source_avatar,          :type => 'string',  :index => 'not_analyzed'
          property :source_nickname,        :type => 'string',  :index => 'not_analyzed'

          property :albums,                 :type => 'object',
            :properties => {
              :id => {:type => "string", :index => :not_analyzed },
              :name => { :type => "string", :index => :not_analyzed }
            }

          property :title,                  :type => 'string',  :index => 'analyzed',     :analyzer => 'standard'
          property :url,                    :type => 'string',  :index => 'not_analyzed'
          property :type,                   :type => 'string',  :index => 'not_analyzed'
          property :tags,                   :type => 'string',  :index => 'not_analyzed', :default => [ ]

          property :people,                  :type => 'object',
            :properties => {
              :id => {:type => "string", :index => :not_analyzed },
              :name => { :type => "string", :index => :not_analyzed }
            }

          property :download_height,        :type => 'integer', :index => 'no'
          property :download_width,         :type => 'integer', :index => 'no'
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
          property :removed,                :type => 'boolean', :index => 'not_analyzed'
        end
      end

      # Create the mappings to the ElasticSearch index.
      self.create_mappings

      # Only saves a resource if it does not already exist or if its tags or people tagged
      # have been modified. Updating a search index is an expensive operation and
      # since we are constantly rescanning resources, this method should help
      # migigate the impact on search performance.
      before_save do
        @_updated = false
        @id = Digest::MD5.hexdigest([@provider, @external_id].join(':'))

        @created_at = (@created_at || Time.now).utc
        @updated_at = Time.now.utc
        # Often the save() method is called for every resource that is discovered. Actually updating
        # the index that often is going to cause performance issues.  So, only update the resource
        # if certain properties have changed.
        resource = Resource.find(@id)

        # If the resource does not exist yet, then save it.
        unless resource
          @new_albums = @albums # if a new resource then new albums are the albums. duh
          return true 
        end
        # Album hash keys get converted to string if symbols, so clean that up just in case
        stringify_album_keys
        
        # If new album coming in then save and also set member new album collection, so no need to maintain state on creation
        # Also, keep in mind albums can be removed
        if @remove_albums # remove the albums we are sending in (a little awkward but it works)
          @albums = resource.albums - @albums
          @removed = true if @albums.count == 0 # no more albums, so mark resource removed
        else
          @new_albums = @albums - ((resource.albums ? resource.albums : []) & @albums)
          @albums = resource.albums + @new_albums
          @removed = false if @new_albums.count > 0 # if albums added back, mark resource not removed any longer
        end
        
        # Otherwise check specific resource attributes to decide whether to update the
        # index.  If the following expression returns `false`, the save operation will
        # be aborted.
        (resource.tags and resource.tags != @tags) or
          (resource.people and resource.people != @people) or
          (resource.albums != @albums) or
          (resource.removed != @removed)
      end

      # Set the @_updated flag to signal that the save operation caused
      # the index to be updated.
      after_save do
        @_updated = true
      end


      def self.inherited(subclass)
        #index_prefix ""
        #index_name "resources"
        #document_type "resource"
        subclass.create_mappings
      end

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
        @tags = []
        @people = []
        @albums = []
        @removed = false
        @remove_albums = false
        @new_albums = []
        super(params)
      end

      # Parses hashtags from the resource's title and description attribute.
      def parse_hashtags
        hashtags = @title.to_s.downcase.scan(/\B#\w+/).uniq.each do |h|
          h.gsub!('#', '').strip!
        end
        hashtags += @description.to_s.downcase.scan(/\B#\w+/).uniq.each do |h|
          h.gsub!('#', '').strip!
        end
        if @tags
          @tags.concat hashtags.uniq
          @tags = @tags.uniq
        else
          @tags = hashtags.uniq
        end
      end

      # A flag that is set when the resource is updated. 
      def updated?
        return @_updated
      end
      
      private
      
      def stringify_album_keys
        @albums.each do |hash|
          hash.keys.each do |key|
            hash[(key.to_s rescue key) || key] = hash.delete(key)
          end
        end
      end

    end

  end
end
