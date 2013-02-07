module Birdbox
  module Search

    # The `Nest` class represents a collection of resources, tied together by
    # one or more hashtags and a collection of owners who contribute resources
    # to the nest.
    class Nest

      # Build a Lucene query based on the values found in the sources parameter.
      #
      # @param [Hash] sources a hash containing one or more providers, each specifying
      #   tags and/or albums.
      # @return [String] a Lucene query string to be used against the Resources index
      #
      def self.build_query_string(sources)
        sources.map { |provider, filters|
          provider_query(provider, filters)
        }.join(' OR ')
      end


      # Build the provider-specific query.  An example of a provider is facebook,
      # which may declare a list of tags and/or albums.
      #
      # @param [String] provider the provider name
      # @param [Hash] filters a list of tags and/or albums
      #
      def self.provider_query(provider, filters)
        q = [ ]
        if filters['albums'] and not filters['albums'].empty?
          q.push(
            #"(#{
              filters.fetch('albums', [ ]).map { |album| 
                "album:\"#{album}\""
              }.join(' OR ')
            #})"
          )
        end
       
        if filters['tags'] and not filters['tags'].empty?
          q.push(
            #"(#{
              filters.fetch('tags', { }).map { |owner,tags|
                "(owner_uid:\"#{owner}\" AND (#{tags.map {|tag| "tags:\"#{tag}\""}.join(' OR ')}))"
              }.join(' OR ')
            #})"
          )
        end
        "(provider:\"#{provider}\" AND (#{q.join(' OR ')}))"
      end


      # Fetches all resources associated with a nest. A resource belongs to a
      # nest if its tag matches one or more of the nest's tags and is owned by
      # one of the nest's owners.
      #
      # @example
      #   sources = {
      #     'facebook' => {
      #       'albums' => %w(132212),
      #       'tags' => { 
      #         '144251' => %w(kiddos vacation),
      #         '235967' => %w(mexico)
      #       }
      #     },
      #     'instagram' => {
      #       'tags' => {
      #         '156832' => %w(springbreak),
      #         '124560' => %w(cabo) 
      #       }
      #     }
      #   }
      #   options = { :page => 1, :page_size => 25, :sort_by => 'uploaded_at' }
      #   results = Birdbox::Search::Nest.fetch(sources, options)
      #   results.each { |result| puts result.my_field }
      # 
      # @param [Hash] sources a hash containing one or more providers, each specifying
      #   tags and/or albums.
      # @param [Hash] options a hash of optional parameters.
      # @return [Tire::Results::Collection] an iterable collection of results
      #
      def self.fetch(sources, options = { })
        # if no query parameters go away
        if sources.keys.count == 0
          return []
        end
        
        opts = {
          :sort_by        => :uploaded_at,  # sort field
          :sort_direction => 'desc',        # sort direction            
          :page           => 1,             # the pagination index
          :page_size      => 10,            # number of items to return per page
          :since          => nil,           # default to the beginning of time
          :until          => nil            # default to the end of time
        }.merge(options)

        # Build the query string based the 'sources' parameter
        q = self.build_query_string(sources)

        # Build the date range query if this request is time-bounded.
        if opts[:since] or opts[:until]
          from_date = Time.at(opts[:since].to_i).utc
          until_date = opts[:until] ? Time.at(opts[:until].to_i).utc : Time.now.utc
          q = "(#{q}) AND (uploaded_at:[#{from_date.strftime("%Y-%m-%dT%H:%M:%S")} TO #{until_date.strftime("%Y-%m-%dT%H:%M:%S")}])"
        end

        #puts "\n#{q}\n"
        search = Tire.search(Birdbox::Search::Resource.index_name) { |search|
          search.query { |query|
            query.string q
          }

          if opts[:sort_by]
            search.sort { 
              by opts[:sort_by], opts[:sort_direction] || 'desc' 
              by :external_id, 'asc'
            }
          end

          page = opts[:page].to_i
          page_size = opts[:page_size].to_i
          search.from (page - 1) * page_size
          search.size page_size
        }
        search.results    
      end


      # Finds the ids of people that are tagged in the resources matching the
      # provided owners and tags.
      #
      # @example
      #   sources = {
      #     'facebook' => {
      #       'albums' => %w(132212),
      #       'tags' => { 
      #         '144251' => %w(kiddos vacation),
      #         '235967' => %w(mexico)
      #       }
      #     },
      #     'instagram' => {
      #       'tags' => {
      #         '156832' => %w(springbreak),
      #         '124560' => %w(cabo) 
      #       }
      #     }
      #   }
      #   people = Birdbox::Search::Nest.find_tagged_people(sources)
      #   people.each { |p| puts "#{p[0]} was tagged #{p[1]} times }
      # 
      # @param [Hash] sources a hash containing one or more providers, each specifying
      #   tags and/or albums.
      # @return [Array] a list of user ids and the associated count
      #
      def self.find_tagged_people(sources)
        # Build the query string based the 'sources' parameter
        q = self.build_query_string(sources)
        Resource.search {
          query { string q }
          facet('people') { terms :people }
        }.facets['people']['terms'].map do |f|
          [f['term'], f['count']]
        end
      end
    end

  end
end
