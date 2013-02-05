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
    Resource.index.import(Fixtures.resources)
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
    ascending = Nest.fetch(members, tags, :sort_by => :uploaded_at, :sort_direction => 'asc').map { |r| r.created_at }
    descending = Nest.fetch(members, tags, :sort_by => :uploaded_at, :sort_direction => 'desc').map { |r| r.created_at }
    descending.to_a.must_equal(ascending.to_a.reverse)
  end

  it "must support time-bounded queries" do
    members = { :facebook => ['100001', '100002'], :twitter => ['200001', '200002'] }
    tags = %w(california cheeseburger)
    results = Nest.fetch(members, tags, :since => Time.parse("2013-01-01 00:00:00").to_i)
    results.count.must_equal(4)
    results = Nest.fetch(members, tags, :until => Time.parse("2012-12-31 23:59:59").to_i)
    results.count.must_equal(2)
    results = Nest.fetch(members, tags, :since => Time.parse("2012-12-01 00:00:00").to_i, :until => Time.parse("2012-12-31 23:59:59").to_i)
    results.count.must_equal(1)
  end

  it "must be able to find all people tagged in the resources belonging to a nest" do
    people = Nest.find_tagged_people({:facebook => ['100001', '100002']}, ['california'])
    people.count.must_equal(3)
    people[0].first.must_equal('facebook:000003')
    people[0].last.must_equal(2)
  end

end
