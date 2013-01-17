require_relative '../test_helper'

describe Birdbox::Search::Nest do
  Resource = Birdbox::Search::Resource
  Nest = Birdbox::Search::Nest

  before do
    Resource.index.delete
    Resource.create_elasticsearch_index
    @items = [ 
      Resource.new(:id => 'facebook:1', :provider => "facebook", :external_id => "1",
        :owner_uid => "100001", :owner_nickname => "alice", :title => "Purple sunset",
        :type => "photo", :description => "A purple sunset off the coast of Isla Vista, CA",
        :url => "http://www.example.com/isla_vista.jpg", :tags => %w(california),
        :height => 640, :width => 480, :created_at => Time.now.utc),

      Resource.new(:id => 'facebook:2', :provider => "facebook", :external_id => "2",
        :owner_uid => "100001", :owner_nickname => "alice", :title => "Bidwell Park",
        :type => "photo", :description => "Enjoying a long hike in Bidwell Park.",
        :url => "http://www.example.com/bidwell.jpg", :tags => %w(california),
        :height => 640, :width => 480, :created_at => Time.now.utc),

      Resource.new(:id => 'facebook:3', :provider => "facebook", :external_id => "3",
        :owner_uid => "100001", :owner_nickname => "alice", :title => "That looks delicious",
        :type => "photo", :description => "That's the best looking cheesebuger I've seen in quite a while",
        :url => "http://www.example.com/cheeseburger.jpg", :tags => %w(cheeseburger),
        :height => 640, :width => 480, :created_at => Time.now.utc),

      Resource.new(:id => 'twitter:1', :provider => "twitter", :external_id => "1",
        :owner_uid => "200001", :owner_nickname => "alice", :title => "The Golden Gate",
        :type => "photo", :description => "Look at that, not a cloud in the sky.",
        :url => "http://www.example.com/golden_gate.jpg", :tags => %w(california),
        :height => 640, :width => 480, :created_at => Time.now.utc),

      Resource.new(:id => 'twitter:2', :provider => "twitter", :external_id => "2",
        :owner_uid => "200002", :owner_nickname => "bob", :title => "The Golden Gate",
        :type => "photo", :description => "Look at that, not a cloud in the sky.",
        :url => "http://www.example.com/golden_gate.jpg", :tags => %w(california),
        :height => 640, :width => 480, :created_at => Time.now.utc),
    ]
    Resource.index.import(@items)
    Resource.index.refresh
  end
  
  it "must be able to retrieve the resources belonging to a nest" do
    members = { :facebook => ['100001'], :twitter => ['200001', '200002'] }
    tags = %w(california)
    nest = Nest.new(members, tags)
    results = nest.fetch
    results.count.must_equal(4)
  end

end
