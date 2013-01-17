module Birdbox
  module Search

    module Searchable
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

    class Resource
      include Tire::Model::Persistence
      include Tire::Model::Search
      include Tire::Model::Callbacks
      include Birdbox::Search::Searchable

      OPTIMUM_WIDTH = 220

      # NOTE: mappings are only applied when calling Resource.create_elasticsearch_index.  Using
      # Resource.index.create will create a generic index with no mappings.
      # parse out any hashtags from title and description and add to tag collection
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

      def persist
        # if resource not in index or tag collection different then save
        # return 0 or 1 (if exists or not) - caller will bump resource count
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
