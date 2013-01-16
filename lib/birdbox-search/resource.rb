module Birdbox
  module Search
    class Resource
      include Tire::Model::Persistence
      include Tire::Model::Search
      include Tire::Model::Callbacks

      OPTIMUM_WIDTH = 220
      
      index_prefix ""
      index_name "resources"
      document_type "resource"

      # NOTE: mappings are only applied when calling Resource.create_elasticsearch_index.  Using
      # Resource.index.create will create a generic index with no mappings.
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
        property :checksum,         :type => 'string',  :index => 'no'
        property :owned,            :type => 'boolean', :index => 'not_analyzed'
      end

      # parse out any hashtags from title and description and add to tag collection
      def parse_hashtags
        hashtags = self.title.to_s.downcase.scan(/\B#\w+/).uniq.each do |h|
          h.gsub!('#', '').strip!
        end
        hashtags += self.description.to_s.downcase.scan(/\B#\w+/).uniq.each do |h|
          h.gsub!('#', '').strip!
        end
        self.tags << hashtags.uniq
        self.tags = self.tags.uniq
      end
      
      def persist
        # if resource not in index or tag collection different then save
        # return 0 or 1 (if exists or not)
        ret = 0
        self.id = "#{self.provider}:#{self.external_id}"
        
        resource = Resource.find(self.id)
        # Won't work outside of a Rails context. For example, it breaks the tests.  Tire has
        # a way to configure loggers and I will look into that.  Use 'puts' for now or comment
        # out the line before checking in the code.
        #Rails.logger.debug "presisting id=#{self.id} resource=#{resource.inspect} self={self.inspect}"
        if !resource or resource.tags != self.tags
          self.save
          ret = 1
          # No need to call this.  The index will refresh almost immediately and forcing it
          # will cause performance issues.
          #self.index.refresh
        end
        ret
      end
      
      # SOME CONVENIENCE STATIC WRAPPER I CAN CALL FORM THE PERCH API
      # def self.find(provider_uids, tags, since=nil, untihl=nil, count=20)
        # # providers = {'facebook' => ['70712020', '110001002359'], 'twitter' => ['11345923']}
        # # tags = array of tags
        # # since = timestamp - return all results > than since (uploaded_at)
        # # until = timestamp - return all results <= than until (uploaded_at)
        # # count = size of result set
      # end

    end

  end
end
