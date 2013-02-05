module Birdbox
  module Search

    # The `Nest` class represents a collection of resources, tied together by
    # one or more hashtags and a collection of members who contribute resources
    # to the nest.
    class Nest

      # Fetches all resources associated with a nest. A resource belongs to a
      # nest if its tag matches one or more of the nest's tags and is owned by
      # one of the nest's members.
      #
      # @example
      #   members = { :facebook => ['123', '456'], :twitter => ['789'] }
      #   options = { :page => 1, :page_size => 25, :sort_by => 'uploaded_at' }
      #   results = Birdbox::Search::Nest.fetch(members, %w(foobar), options)
      #   results.each { |result| puts result.my_field }
      # 
      # @param [Hash] owners keys are made up of the provider names and the values
      #   is an array of user ids specific to that provider.
      # @param [Array] tags an array of string tokens representing tags.
      # @param [Hash] options a hash of optional parameters.
      # @return [Tire::Results::Collection] an iterable collection of results
      def self.fetch(owners, tags, options = { })
        opts = {
          :sort_by        => :uploaded_at,  # sort field
          :sort_direction => 'desc',        # sort direction            
          :page           => 1,             # the pagination index
          :page_size      => 10,            # number of items to return per page
          :since          => nil,           # default to the beginning of time
          :until          => nil            # default to the end of time
        }.merge(options)

        query_tags = tags.map { |t| "tags:\"#{t}\"" }.join(" OR ") 
        query_owners = owners.map { |(k,v)| "(provider:\"#{k}\" AND (#{v.map{ |owner| "owner_uid:\"#{owner}\"" }.join(" OR ")}))" }.join(" OR ")
        q = "(#{query_tags}) AND (#{query_owners})"

        # Build the date range query if this request is time-bounded.
        if opts[:since] or opts[:until]
          from_date = Time.at(opts[:since].to_i)
          until_date = opts[:until] ? Time.at(opts[:until]) : Time.now.utc
          q += " AND (updated_at:[#{from_date.strftime("%Y-%m-%dT%H:%M:%S")} TO #{until_date.strftime("%Y-%m-%dT%H:%M:%S")}])"
        end

        search = Tire.search(Birdbox::Search::Resource.index_name) { |search|
          search.query { |query|
            query.string q
          }

          if opts[:sort_by]
            search.sort { by opts[:sort_by], opts[:sort_direction] || 'desc' }
          end

          page = opts[:page].to_i
          page_size = opts[:page_size].to_i
          search.from (page - 1) * page_size
          search.size page_size
        }
        search.results    
      end

      attr_accessor :owners, :tags

      # Creates a new instance of a Nest object.
      #
      # @param [Hash] owners keys are made up of the provider names and the values
      #   is an array of user ids specific to that provider.
      # @param [Array] tags an array of string tokens representing tags.
      # @return [Nest] a nest object
      def initialize(owners, tags)
        @owners = owners || { }
        @tags = tags || [ ]
      end

      # Fetches all resources associated with a nest. A resource belongs to a
      # nest if its tag matches one or more of the nest's tags and is owned by
      # one of the nest's members.
      #
      # @example
      #   members = { :facebook => ['123', '456'], :twitter => ['789'] }
      #   nest = Birdbox::Search::Nest.new(members, %w(foobar))
      #   results = nest.fetch(:page => 1, :page_size => 25)
      #   results.each { |result| puts result.my_field }
      # 
      # @param [Hash] options a hash of optional parameters.
      # @return [Tire::Results::Collection] an iterable collection of results
      def fetch(options={ })
        Nest.fetch(self.owners, self.tags)
      end

    end

  end
end
