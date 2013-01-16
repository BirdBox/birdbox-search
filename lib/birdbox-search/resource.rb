module Birdbox
  module Search
    class Resource
      include Tire::Model::Persistence

      OPTIMUM_WIDTH = 220
      
      index_prefix ""
      index_name "resources"

      validates_presence_of :source, :owner, :type, :url
      #validates_format_of :height, :allow_nil => true, :with => /\d+/
      #validates_format_of :width, :allow_nil => true, :with => /\d+/

      # use this for resource id :id = "#{provider}:#{external_id}"
      property :provider,         :type => 'string', :analyzer => 'keyword'
      property :external_id,      :type => 'string', :index => 'not_indexed'
      property :owner_uid,        :type => 'string', :analyzer => 'keyword'
      property :owner_nickname,   :type => 'string', :analyzer => 'keyword'
      property :title,            :type => 'string', :analyzer => 'snowball'
      property :url,              :type => 'string', :index => 'not_indexed'
      property :type,             :type => 'string', :analyzer => 'keyword'
      property :tags,             :default => [ ], :index => 'keyword'
      property :height,           :type => 'integer', :index => 'not_indexed'
      property :width,            :type => 'integer', :index => 'not_indexed'
      property :uploaded_at,      :type => 'date'
      property :taken_at,         :type => 'date'
      property :description,      :type => 'string', :analyzer => 'snowball'
      property :download_uri,     :type => 'string', :index => 'not_indexed'
      property :thumbnail_uri,    :type => 'string', :index => 'not_indexed'
      property :thumbnail_height, :type => 'integer', :index => 'not_indexed'
      property :thumbnail_width,  :type => 'integer', :index => 'not_indexed'
      property :html,             :type => 'string', :index => 'not_indexed'
      # ??
      property :owned,            :type => 'boolean', :analyzer => 'keyword'
      
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
        # return 0 or 1
        ret = 0
        index = Tire::Index.new(index_name)
        id = #{self.provider}:#{self.external_id}"
        resource = index.find(id)
        Rails.logger.debug "presisting id=#{id} resource=#{resource.inspect} self={self.inspect}"
        if !resource or resource.tags != self.tags
          self[:id] = id
          index.store self
          ret = 1
          index.refresh
        end
        ret
      end
      
      def self.find(provider_uids, tags, since=nil, untihl=nil, count=20)
        # providers = {'facebook' => ['70712020', '110001002359'], 'twitter' => ['11345923']}
        # tags = array of tags
        # since = timestamp - return all results > than since
        # until = timestamp - return all results <= than until
        # count = size of result set
      end

    end

  end
end
