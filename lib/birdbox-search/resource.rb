require 'digest/md5'

module Birdbox
  module Search

    # The Resource class wraps an Elasticsearch index by the same name. Note that the 
    # mappings are only applied when calling Resource.create_elasticsearch_index.
    # Using Resource.index.create will create a generic index with no mappings.
    class Resource
      attr_accessor :nest_ids
      attr_accessor :remove_albums
      attr_accessor :new_albums
      #include Tire::Model::Persistence
      include Elasticsearch::Persistence::Model

      index_name "resources"

      # user has many authentication which has many services, so if we EVER want to tie the resource to a service, unfortunately
      # we have to persist the service somehow (and do not want to couple these togther) - so add a service name
      # think of google as the authentication provider and 'picasa, g+, gmail, etc as the services'
      attribute :service, String,  :index => 'not_analyzed'
      attribute :provider, String,  :index => 'not_analyzed'
      attribute :external_id, String,  :index => 'not_analyzed'
      attribute :action_session_id, String,  :index => 'not_analyzed'
      attribute :owner_uid, String,  :index => 'not_analyzed'
      attribute :owner_birdbox_name, String,  :index => 'not_analyzed'
      attribute :owner_birdbox_nickname, String,  :index => 'not_analyzed'
      attribute :source_uid, String,  :index => 'not_analyzed'
      attribute :source_nickname, String,  :index => 'not_analyzed'

      attribute :title, String,  :index => 'analyzed',     :analyzer => 'standard'
      attribute :url, String,  :index => 'not_analyzed'
      attribute :type, String,  :index => 'not_analyzed'
      attribute :tags, String,  :index => 'not_analyzed', :default => [ ]
      attribute :nests, Integer,  :index => 'not_analyzed', :default => [ ]

      attribute :download_height, Integer, :index => 'no'
      attribute :download_width, Integer, :index => 'no'
      attribute :created_at, DateTime,    :index => 'not_analyzed', default: lambda { |o,a| Time.now.utc }
      attribute :updated_at, DateTime,    :index => 'not_analyzed', default: lambda { |o,a| Time.now.utc }
      attribute :uploaded_at, DateTime,    :index => 'not_analyzed', default: lambda { |o,a| Time.now.utc }
      attribute :taken_at, Date,    :index => 'not_analyzed'
      attribute :description, String,  :index => 'analyzed',     :analyzer => 'standard'
      attribute :download_url, String,  :index => 'no'
      attribute :thumbnail_url_small, String,  :index => 'no'
      attribute :thumbnail_height_small, Integer, :index => 'no'
      attribute :thumbnail_width_small, Integer, :index => 'no'
      attribute :thumbnail_url_medium, String,  :index => 'no'
      attribute :thumbnail_height_medium, Integer, :index => 'no'
      attribute :thumbnail_width_medium, Integer, :index => 'no'
      attribute :thumbnail_url_large, String,  :index => 'no'
      attribute :thumbnail_height_large, Integer, :index => 'no'
      attribute :thumbnail_width_large, Integer, :index => 'no'
      attribute :html, String,  :index => 'no'
      attribute :owned, Boolean, :index => 'not_analyzed'
      attribute :removed, Boolean, :index => 'not_analyzed'

      def self.generate_id(provider, external_id)
        Digest::MD5.hexdigest([provider, external_id].join(':'))
      end

      # Only saves a resource if it does not already exist or if its tags or people tagged
      # have been modified. Updating a search index is an expensive operation and
      # since we are constantly rescanning resources, this method should help
      # migigate the impact on search performance.
      before_save do
        save = true
        @nest_ids = @nests.dup
        @_updated = false
        @id = Resource.generate_id(@provider, @external_id)
        @created_at = @updated_at = Time.now.utc
        
        @taken_at ||= Time.now.utc
        
        @uploaded_at ||= Time.now.utc
        
        # Often the save() method is called for every resource that is discovered. Actually updating
        # the index that often is going to cause performance issues.  So, only update the resource
        # if certain properties have changed.
        resource = Resource.find(@id) rescue nil
        
        # If the resource does not exist yet, then save it, else update
        if resource and resource.id

          # just concat the new nest(s) to any existing and keep the 'old' relevant timestamps (updated_at will change)
          @created_at = resource.created_at
          @uploaded_at = resource.uploaded_at
          @taken_at = resource.taken_at
          
          @nests.concat resource.nests
          @nests.uniq!
          
          # Otherwise check specific resource attributes to decide whether to update the
          # index.  If the following expression returns `false`, the save operation will
          # be aborted.
          save = (
            resource.tags != @tags or
            resource.nests != @nests or
            resource.people != @people or
            resource.albums != @albums or
            resource.removed != @removed
          )
        end
        @_updated = save
        save
      end


      # When a 3rd party (such as facebook) yields multiple thumbnails pick the one that is closest (larger preferred) to the desired width
      OPTIMUM_THUMBNAIL_WIDTH_SMALL = 70
      OPTIMUM_THUMBNAIL_WIDTH_MEDIUM = 270
      OPTIMUM_THUMBNAIL_WIDTH_LARGE = 370


      # Queries the search index using the provided terms.
      # 
      # @example
      #  Resource.query(owner_uid => 54321012, :service_id => [1, 2]) 
      #
      # @param [Hash] a dictionary of terms
      # @return [Tire::Results::Collection] an iterable collection of results

      # def self.query(terms={ })
      #   return nil if terms.empty?
      #
      #   filter = terms.inject([ ]) { |memo,(k,v)|
      #     if v.is_a?(Array)
      #       memo.push({:terms => {k => v}})
      #     else
      #       memo.push({:term => {k => v}})
      #     end
      #     memo
      #   }
      #
      #   if filter.count == 1
      #     filter = filter.first
      #   else
      #     filter = {:and => filter}
      #   end
      #
      #   Tire.search('resources', {
      #     :query => {
      #       :filtered => {
      #         :query => {:match_all => { }},
      #         :filter => filter
      #       }
      #     }
      #   }).results
      # end

    end

  end
end