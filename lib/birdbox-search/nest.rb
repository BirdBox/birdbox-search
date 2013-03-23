require 'time'

module Birdbox
  module Search

    # The `Nest` class represents a collection of resources, tied together by
    # one or more hashtags and a collection of owners who contribute resources
    # to the nest.
    class Nest

      # Build the provider-specific filter.  An example of a provider is facebook,
      # which may declare a list of tags and/or albums.
      #
      # @param [String] provider the provider name
      # @param [Hash] filters a list of tags and/or albums
      #
      def self.build_provider_statement(provider, data)
        filter = { }
        case provider.to_s.strip.downcase
          when "facebook"
            albums = data.fetch('albums', [ ])
            if albums.empty?
              raise ArgumentError.new 'Query must specify at least one facebook album.'
            else
              filter[:and] = [
                {:term => {:provider => 'facebook'}},
                {:terms => {'albums.id' => albums}},
              ] 
            end
          when "instagram"
            tags = data.fetch('tags', { })
            if tags.empty?
              raise ArgumentError.new 'Query must specify at least one instagram tag.'
            elsif tags.count == 1
              filter[:and] = [
                {:term => {:provider => 'instagram'}},
                {:term => {:owner_uid => tags.keys.first}},
                {:terms => {:tags => tags.values.first}},
              ]
            else
               filter[:and] = [
                {:term => {:provider => 'instagram'}},
                {
                  :or => tags.inject([ ]) do |memo, (owner,tags)|
                    memo.push({
                      :and => [
                        {:term => {:owner_uid => owner}},
                        {:terms => {:tags => tags}}
                      ]
                    })
                    memo
                  end
                }
              ] 
            end
          else
            raise ArgumentError.new("invalid provider (#{provider}")
        end
        filter
      end


      # Builds an ElasticSearch query based on the values found in the sources parameter.
      #
      # @param [Hash] sources a hash containing one or more providers, each specifying
      #   tags and/or albums.
      # @param [Hash] options a hash of optional parameters
      # @return [Hash] a hash containing the ElasticSearch DSL payload.
      #
      def self.build_query_filter(sources, options)
        opts = {
          :since          => nil,           # default to the beginning of time
          :until          => nil,           # default to the end of time
          :exclude        => [ ]            # excluded resource ids
        }.merge(options)

        filters = [ ]

        # Build the provider statements from the `sources` parameter.  At least one
        # provider is required.  If there's more than one provider, wrap all of the 
        # provider queries into an `or` block.
        providers = sources.map { |provider, data|
          build_provider_statement(provider, data) 
        }

        if providers.empty?
          raise ArgumentError.new('Query must specify at least one provider.')
        elsif providers.count == 1
          filters.push(providers.first)
        else
          filters.push({:or => providers})
        end

        # Limit the query to a specific date range if the `since` and/or `until` parameter
        # have been specified.
        if opts[:since] or opts[:until]
          from_date = Time.at(opts[:since].to_i).utc
          until_date = opts[:until] ? Time.at(opts[:until].to_i).utc : Time.now.utc
          filters.push({
            :range => {
              :uploaded_at => {
                :from => from_date.iso8601,
                :to => until_date.iso8601,
                :include_lower => false,
                :include_upper => true
              }
            }
          })
        end

        # The external_id of a resource can be used to resolve pagination conflicts when 
        # several resources have the same uploaded_at timestamp.
        if opts[:external_id]
          # from_external_id = opts[:external_id]
          # to_external_id  = 0
          # if opt[:sort_direction].eql? 'asc' # if paging the other direction then flip the secondary sort as well 
            # from_external_id = opts[:external_id]
            # to_external_id  = nil # unbounded
          # end
          
          # unbounded range query (sort order sets the boundaries and direction)
          filters.push({
            :range => {
              :external_id => {
                :from => opts[:external_id],
                :include_lower => false,
                :include_upper => true
              }
            }
          })
        end 

        # Check if there are any resources that should be excluded.  If so, the query will need to
        # be modified to NOT include the items on the list.
        unless (opts[:exclude].empty?)
          filters.push({
            :not => {:terms => { :_id => opts[:exclude], :execution => 'or'}}
          })
        end

        # Don't include resources that have been removed from the provider (e.g. a user
        # deletes an image from Facebook).
        filters.push({:term => {:removed => false}})

        # Last but not least, wrap the whole thing into a `and` block.
        {:and => filters }

      end



      # Fetches all resources associated with a nest. A resource belongs to a
      # nest if its tag matches one or more of the nest's tags and is owned by
      # one of the nest's owners.
      #
      # @example
      #   sources = {
      #     'facebook' => {
      #       'albums' => %w(132212 687261)
      #     },
      #     'instagram' => {
      #       'tags' => {
      #         '156832' => %w(springbreak),
      #         '124560' => %w(cabo mexico) 
      #       }
      #     }
      #   }
      #   options = { :page => 1, :page_size => 25, :sort_by => 'uploaded_at', 
      #     :exclude => ['facebook:432115', 'facebook:632613'] }
      #   results = Birdbox::Search::Nest.fetch(sources, options)
      #   results.each { |result| puts result.my_field }
      # 
      # @param [Hash] sources a hash containing one or more providers, each specifying
      #   tags and/or albums.
      # @param [Hash] options a hash of optional parameters.
      # @return [Tire::Results::Collection] an iterable collection of results
      #
      def self.fetch(sources, options = { })
        opts = {
          :sort_by        => :uploaded_at,  # sort field
          :sort_direction => 'desc',        # sort direction            
          :page           => 1,             # the pagination index
          :page_size      => 10,            # number of items to return per page
          :since          => nil,           # default to the beginning of time
          :until          => nil,           # default to the end of time
          :exclude        => [ ],           # excluded resource ids
          :external_id    => nil            # used to resolve conflicts when uploaded_at is not unique
        }.merge(options)

        # if no query parameters go away
        if sources.keys.count == 0
          return []
        end
        
        # NEED this so if we have multiple resources (>= page size) w/ the same uploaded_at timestamp we can get the next batch
        # if opts[:external_id]
          # q = "(#{q}) AND (external_id:[0 TO #{opts[:external_id]}])"
        # end

        # Select the options needed to build the query filter into their own hash.
        filter_options = opts.select{ |k,v| [:since, :until, :exclude, :external_id].include?(k) }
        
        query = {
          :query => {
            :filtered => {
              :query => { :match_all => { } },
              :filter => self.build_query_filter(sources, filter_options)
            }
          },
          :sort => [
            { :external_id => opts[:sort_direction] }
          ],
          :from => opts[:page_size].to_i * (opts[:page].to_i - 1),
          :size => opts[:page_size].to_i 
        }

        # Add the custom search parameter if one was provided.
        if opts[:sort_by]
          query[:sort].insert(0, {opts[:sort_by] => opts[:sort_direction]}) 
        end

        search = Tire.search 'resources', query
        search.results
      end


      # return all matching resources - used for nest exemptions fetching
      # if owner_uid colelction, then only resources for all this owner's authentication uid's
      def self.fetch_ids(ids, owner_uid=nil)
        query = {
          :query => 
          {
              :filtered => {
                :query => {
                  :ids => {
                    :type => Birdbox::Search::Resource.document_type,
                    :values => ids
                  }
                }
              }
          }
        }
        query[:query][:filtered][:filter] = {:terms => {:owner_uid => owner_uid}} if owner_uid
        search = Tire.search Birdbox::Search::Resource.index_name, query
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
      #   people = Birdbox::Search::Nest.find_tagged_people(sources, :size => 5)
      #   people.each { |p| puts "#{p[0]} was tagged #{p[1]} times" }
      # 
      # @param [Hash] sources a hash containing one or more providers, each specifying
      #   tags and/or albums.
      # @return [Array] a list of user ids and the associated count
      #
      def self.find_tagged_people(sources, options={ })
        opts = {
          :page_size      => 10,            # number of items to return per page
          :since          => nil,           # default to the beginning of time
          :until          => nil,           # default to the end of time
          :exclude        => [ ]            # excluded resource ids
        }.merge(options)
        
        # Select the options needed to build the query filter into their own hash.
        filter_options = opts.select{ |k,v| [:since, :until, :exclude].include?(k) }

        # Build the query based the 'sources' parameter
         query = {
          :query => {
            :filtered => {
              :query => { :match_all => { } },
              :filter => self.build_query_filter(sources, filter_options)
            }
          },
          :facets => {
            :people => {
              :terms => {
                :field => 'people.id'
              }
            }
          } 
        }

        search = Tire.search 'resources', query
        search.results.facets['people']['terms'].map do |f|
          [f['term'], f['count']]
        end

      end

    end

  end
end
