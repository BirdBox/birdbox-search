require 'time'
require_relative '../test_helper'

describe Birdbox::Search::Nest do
  Resource = Birdbox::Search::Resource
  Nest = Birdbox::Search::Nest

  Birdbox::Search.configure do
    url 'http://localhost:9200'
    #logger STDERR, :debug => true
  end


  before do
    Resource.index.delete
    Resource.create_elasticsearch_index
    @items = [ 
      Resource.new(:id => 'facebook:1', :provider => "facebook", :external_id => "1",
        :owner_uid => "100001", :owner_nickname => "alice", :title => "Purple sunset",
        :type => "photo", :description => "A purple sunset off the coast of Isla Vista, CA",
        :url => "http://www.example.com/isla_vista.jpg", :tags => %w(california),
        :height => 640, :width => 480, :created_at => Time.parse("2013-01-01 00:02:14")),

      Resource.new(:id => 'facebook:2', :provider => "facebook", :external_id => "2",
        :owner_uid => "100001", :owner_nickname => "alice", :title => "That looks delicious",
        :type => "photo", :description => "That's the best looking cheesebuger I've seen in quite a while",
        :url => "http://www.example.com/cheeseburger.jpg", :tags => %w(cheeseburger),
        :height => 640, :width => 480, :created_at => Time.parse("2013-01-18 15:26:42")),

      Resource.new(:id => 'facebook:3', :provider => "facebook", :external_id => "3",
        :owner_uid => "100002", :owner_nickname => "bob", :title => "Bidwell Park",
        :type => "photo", :description => "Enjoying a long hike in Bidwell Park.",
        :url => "http://www.example.com/bidwell.jpg", :tags => %w(california),
        :height => 640, :width => 480, :created_at => Time.parse("2013-01-10 22:34:07")),

      Resource.new(:id => 'twitter:1', :provider => "twitter", :external_id => "1",
        :owner_uid => "200001", :owner_nickname => "alice", :title => "The Golden Gate",
        :type => "photo", :description => "Look at that, not a cloud in the sky.",
        :url => "http://www.example.com/golden_gate.jpg", :tags => %w(california),
        :height => 640, :width => 480, :created_at => Time.parse("2013-01-02 13:04:11")),

      Resource.new(:id => 'twitter:2', :provider => "twitter", :external_id => "2",
        :owner_uid => "200002", :owner_nickname => "bob", :title => "The Golden Gate",
        :type => "photo", :description => "Look at that, not a cloud in the sky.",
        :url => "http://www.example.com/golden_gate.jpg", :tags => %w(california),
        :height => 640, :width => 480, :created_at => Time.parse("2012-12-05 9:23:56")),

      Resource.new(:id => 'twitter:3', :provider => "twitter", :external_id => "3",
        :owner_uid => "200002", :owner_nickname => "bob", :title => "Hearst Castle",
        :type => "photo", :description => "Damn, nice crib.",
        :url => "http://www.example.com/hearst_castle.jpg", :tags => %w(california),
        :height => 640, :width => 480, :created_at => Time.parse("2012-11-15 16:12:41")),

    ]
    Resource.index.import(@items)
    Resource.index.refresh
  end
  
  it "must be able to fetch resources for a single tag and a single owner" do
    results = Nest.fetch({:facebook => ['100001']}, ['california'])
    results.count.must_equal(1)
  end

  it "must be able to fetch resources for a single tag and multiple owners" do
    results = Nest.fetch({:facebook => ['100001', '100002'], :twitter => ['200001']}, ['california'])
    results.count.must_equal(3)
  end

  it "must be able to fetch resources for multiple tags" do
    results = Nest.fetch({:facebook => ['100001', '100002']}, %w(cheeseburger california))
    results.count.must_equal(3)
  end

  it "must be able to paginate results" do
    members = { :facebook => ['100001', '100002'], :twitter => ['200001', '200002'] }
    tags = %w(california cheeseburger)
    results = Nest.fetch(members, tags, :page => 1, :page_size => 5)
    results.count.must_equal(5)
    results = Nest.fetch(members, tags, :page => 2, :page_size => 5)
    results.count.must_equal(1)
  end

  it "must be able to sort results" do
    members = { :facebook => ['100001', '100002'], :twitter => ['200001', '200002'] }
    tags = %w(california cheeseburger)
    ascending = Nest.fetch(members, tags, :sort_by => :created_at, :sort_direction => 'asc').map { |r| r.created_at }
    descending = Nest.fetch(members, tags, :sort_by => :created_at, :sort_direction => 'desc').map { |r| r.created_at }
    descending.to_a.must_equal(ascending.to_a.reverse)
  end

  it "must support time-bounded queries" do
    members = { :facebook => ['100001', '100002'], :twitter => ['200001', '200002'] }
    tags = %w(california cheeseburger)
    results = Nest.fetch(members, tags, :since => Time.parse("2013-01-01 00:00:00"))
    results.count.must_equal(4)
    results = Nest.fetch(members, tags, :until => Time.parse("2012-12-31 23:59:59"))
    results.count.must_equal(2)
    results = Nest.fetch(members, tags, :from => Time.parse("2012-11-01 00:00:00"), :until => Time.parse("2012-11-31 23:59:59"))
    results.count.must_equal(1)
  end

end
