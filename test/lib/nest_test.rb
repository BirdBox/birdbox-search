require_relative '../test_helper'

describe Birdbox::Search::Nest do
  Resource = Birdbox::Search::Resource
  Nest = Birdbox::Search::Nest

  before do
    Resource.index.delete
    Resource.create_elasticsearch_index
    @items = [ 
      Resource.new(:id => 'facebook:1', :provider => "facebook", :external_id => "1",
        :owner_uid => "123456", :owner_nickname => "me", :title => "Purple sunset",
        :type => "photo", :description => "A purple sunset off the coast of Isla Vista, CA",
        :url => "http://www.example.com/foo.jpg", :tags => %w(california),
        :height => 640, :width => 480, :created_at => Time.now.utc),

      Resource.new(:id => 'twitter:1', :provider => "facebook", :external_id => "1",
        :owner_uid => "123456", :owner_nickname => "me", :title => "That looks delicious",
        :type => "photo", :description => "That's the best looking cheesebuger I've seen in quite a while",
        :url => "http://www.example.com/bar.jpg", :tags => %w(cheeseburger),
        :height => 640, :width => 480, :created_at => Time.now.utc),

      Resource.new(:id => 'facebook:3', :provider => "facebook", :external_id => "3",
        :owner_uid => "654321", :owner_nickname => "notme", :title => "The Golden Gate",
        :type => "photo", :description => "Look at that, not a cloud in the sky.",
        :url => "http://www.example.com/baz.jpg", :tags => %w(california),
        :height => 640, :width => 480, :created_at => Time.now.utc),
    ]
    Resource.index.import(@items)
    Resource.index.refresh
  end
  
  it "must be able to retrieve the resources belonging to a nest" do
    members = { :facebook => ['123456'], :twitter => ['999999' ] }
    tags = %w(california)
    nest = Nest.new(members, tags)
    results = nest.fetch
    puts results.count
  end

end
