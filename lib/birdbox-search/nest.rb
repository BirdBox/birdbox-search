module Birdbox
  module Search

    class Nest
      attr_accessor :members, :tags

      def initialize(members, tags)
        @members = members || { }
        @tags = tags || [ ]
      end


      def fetch(options={ })
        opts = {
          :count => 20,
          :since => nil,
          :until => nil 
        }.merge(options)

        search = Tire.search('resources') { |search|
          search.query { |query|
            query.terms :tags, self.tags
          }
        }
        search.results    
      end

    end

  end
end
