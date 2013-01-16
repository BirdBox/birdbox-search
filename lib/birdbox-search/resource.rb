module Birdbox
  module Search

    # use this for resource id :id = "#{provider}:#{external_id}"
    class Resource
      include Tire::Model::Persistence
      include Tire::Model::Search
      include Tire::Model::Callbacks

      index_prefix ""
      index_name "resources"
      document_type "resource"

      # NOTE: mappings are only applied when calling Resource.create_elasticsearch_index.  Using
      # Resource.index.create will create a generic index with no mappings.
      mapping do
        property :provider,         :type => 'string',  :index => 'not_analyzed'
        property :owner_uid,        :type => 'string',  :index => 'not_analyzed'
        property :owner_nickname,   :type => 'string',  :index => 'not_analyzed'
        property :title,            :type => 'string',  :index => 'analyzed',     :analyzer => 'standard'
        property :url,              :type => 'string',  :index => 'not_analyzed'
        property :type,             :type => 'string',  :index => 'not_analyzed'
        property :tags,             :type => 'string',  :index => 'analyzed',     :analyzer => 'keyword', :default => [ ]
        property :height,           :type => 'integer', :index => 'no'
        property :width,            :type => 'integer', :index => 'no'
        property :created_at,       :type => 'date',    :index => 'not_analyzed'
        property :taken_at,         :type => 'date',    :index => 'not_analyzed'
        property :description,      :type => 'string',  :index => 'analyzed',     :analyzer => 'standard'
        property :thumbnail_url,    :type => 'string',  :index => 'no'
        property :thumbnail_height, :type => 'integer', :index => 'no'
        property :thumbnail_width,  :type => 'integer', :index => 'no'
        property :html,             :type => 'string',  :index => 'no'
        property :checksum,         :type => 'string',  :index => 'no'
      end

      #validates_presence_of :source, :owner, :type, :url
      #validates_format_of :height, :allow_nil => true, :with => /\d+/
      #validates_format_of :width, :allow_nil => true, :with => /\d+/

    end

  end
end
