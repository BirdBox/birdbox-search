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

    index_alias = Tire::Alias.new
    index_alias.name('resources')
    index_alias.index('resources_v1')
    index_alias.save

    Resource.index.import(Fixtures.resources)
    Resource.index.refresh

  end
  
  it "must be able to fetch resources for a single facebook album" do
    sources = {
      'facebook' => {'albums' => %w(1)}
    }
    results = Nest.fetch(sources)
    results.count.must_equal(2)
  end


  it "must be able to fetch resources for multiple facebook albums" do
    sources = {
      'facebook' => {'albums' => %w(1 2)}
    }
    results = Nest.fetch(sources)
    results.count.must_equal(4)
  end


  it "must be able to fetch resources for a single tag belonging to one instagram user" do
    sources = {
      'instagram' => {
        'tags' => {
          '200002' => %w(california),
        }
      }
    }
    results = Nest.fetch(sources)
    results.count.must_equal(2)
  end


  it "must be able to fetch resources for multiple tags belonging to one instagram user" do
    sources = {
      'instagram' => {
        'tags' => {
          '200002' => %w(california norcal),
        }
      }
    }
    results = Nest.fetch(sources)
    results.count.must_equal(3)
  end


  it "must be able to fetch resources for multiple tags across multiple instagram users" do
    sources = {
      'instagram' => {
        'tags' => {
          '200001' => %w(california),
          '200002' => %w(california norcal),
        }
      }
    }
    results = Nest.fetch(sources)
    results.count.must_equal(4)
  end


  it "must be able to fetch various resources from multiple services" do
    sources = {
      'facebook' => {
        'albums' => %w(1 2)
      },
      'instagram' => {
        'tags' => {
          '200001' => %w(california),
          '200002' => %w(california norcal)
        }
      }
    }
    results = Nest.fetch(sources)
    results.count.must_equal(8)
  end


  it "must be able to paginate over results" do
    sources = {
      'facebook' => {
        'albums' => %w(1 2)
      },
      'instagram' => {
        'tags' => {
          '200001' => %w(california),
          '200002' => %w(california norcal)
        }
      }
    }
    results = Nest.fetch(sources, :page => 1, :page_size => 5)
    results.count.must_equal(5)
    results = Nest.fetch(sources, :page => 2, :page_size => 5)
    results.count.must_equal(3)
  end


  it "must be able to sort results" do
    sources = {
      'facebook' => {
        'albums' => %w(1 2)
      },
      'instagram' => {
        'tags' => {
          '200001' => %w(california),
          '200002' => %w(california norcal)
        }
      }
    }
    ascending = Nest.fetch(sources, :sort_by => :uploaded_at, :sort_direction => 'asc').map { |r| r.updated_at }
    descending = Nest.fetch(sources, :sort_by => :uploaded_at, :sort_direction => 'desc').map { |r| r.updated_at }
    descending.to_a.must_equal(ascending.to_a.reverse)
  end


  it "must support time-bounded queries" do
    sources = {
      'facebook' => {
        'albums' => %w(1 2)
      },
      'instagram' => {
        'tags' => {
          '200001' => %w(california),
          '200002' => %w(california norcal)
        }
      }
    }
    results = Nest.fetch(sources, :until => Time.parse("2011-01-01 00:00:00").to_i)
    results.count.must_equal(0)
    results = Nest.fetch(sources, :since => Time.parse("2011-01-01 00:00:00").to_i)
    results.count.must_equal(8)
    results = Nest.fetch(sources, :since => Time.parse("2013-01-01 00:00:00").to_i)
    results.count.must_equal(5)
    results = Nest.fetch(sources, :until => Time.parse("2012-12-31 23:59:59").to_i)
    results.count.must_equal(3)
    results = Nest.fetch(sources, :since => Time.parse("2012-11-15 00:00:00").to_i, :until => Time.parse("2012-11-15 23:59:59").to_i)
    results.count.must_equal(2)
  end


  it "must be able to find all people tagged in the resources belonging to a nest" do
    sources = {
      'facebook' => {
        'albums' => %w(1 2)
      },
      'instagram' => {
        'tags' => {
          '200001' => %w(california),
          '200002' => %w(california norcal)
        }
      }
    }
    people = Nest.find_tagged_people(sources)
    people.count.must_equal(4)
    people[0].first.must_equal('22')
    people[0].last.must_equal(3)
  end


  it "must be able to exclude resources by id" do
    sources = {
      'facebook' => {
        'albums' => %w(1 2)
      },
      'instagram' => {
        'tags' => {
          '200001' => %w(california),
          '200002' => %w(california norcal)
        }
      }
    }
    exclude = [
      Digest::MD5.hexdigest('facebook:1'),
      Digest::MD5.hexdigest('instagram:3'),
    ]
    results = Nest.fetch(sources, :exclude => exclude)
    results.count.must_equal(6)
  end

  
  it "must be able to fetch resources by ideez" do
    ids = [
      Digest::MD5.hexdigest('facebook:1'),
      Digest::MD5.hexdigest('facebook:4'),
      Digest::MD5.hexdigest('instagram:2'),
    ]
    results = Nest.fetch_ids(ids, ['100001'])
    results.count.must_equal(2)
  end
  
  it "must be able to fetch resources by ideez all users" do
    ids = [
      Digest::MD5.hexdigest('facebook:1'),
      Digest::MD5.hexdigest('facebook:4'),
      Digest::MD5.hexdigest('instagram:2'),
    ]
    results = Nest.fetch_ids(ids)
    results.count.must_equal(3)
  end

end
