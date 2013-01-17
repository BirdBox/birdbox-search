module Birdbox
  module Search

    class Nest

      def self.fetch(owners, tags, options = { })
        opts = {
          :count => 20,   # default to returning 20 items
          :since => nil,  # default to the beginning of time
          :until => nil   # default to the end of time
        }.merge(options)

        tq = tags.map { |t| "tags:\"#{t}\"" }.join(" OR ") 
        mq = owners.map { |(k,v)| "(provider:\"#{k}\" AND (#{v.map{ |owner| "owner_uid:\"#{owner}\"" }.join(" OR ")}))" }.join(" OR ")
        q = "#{tq} AND (#{mq})"

        search = Tire.search(Birdbox::Search::Resource.index_name) { |search|
          search.query { |query|
            query.string q
          }
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

      # Fetches all resources associated with a nest.  The association is determined
      # through a combination of a resources tag(s) and the resources owner on a
      # respective provider (e.g. Facebook, Twitter, etc.).
      # 
      # @param [Hash] options a hash of optional parameters.
      # @return [Tire::Results::Collection] an iterable collection of results
      def fetch(options={ })
        Nest.fetch(self.owners, self.tags)
      end

    end

  end
end
