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
  
  it "must be able to fetch resources for a single tag belonging to a single owner using one service." do
    sources = {
      'facebook' => {
        'tags' => {
          '100001' => %w(california)
        }
      }
    }
    results = Nest.fetch(sources)
    results.count.must_equal(1)
  end

  it "must be able to fetch resources for multiple tags belonging to a single owner using one service" do
    sources = {
      'facebook' => {
        'tags' => {
          '100001' => %w(california norcal)
        }
      }
    }
    results = Nest.fetch(sources)
    results.count.must_equal(2)
  end

  it "must be able to fetch resources for a single tag and multiple owners using one service" do
    sources = {
      'facebook' => {
        'tags' => {
          '100001' => %w(california),
          '100002' => %w(california)
        }
      }
    }
    results = Nest.fetch(sources)
    results.count.must_equal(2)
  end

  it "must be able to fetch resources for a single tag belonging to multiple owners using one service" do
    sources = {
      'facebook' => {
        'tags' => {
          '100001' => %w(california),
          '100002' => %w(california)
        }
      }
    }
    results = Nest.fetch(sources)
    results.count.must_equal(2)
  end

  it "must be able to fetch resources for multiple tags belonging to multiple owners using one service" do
    sources = {
      'facebook' => {
        'tags' => {
          '100001' => %w(norcal),
          '100002' => %w(california)
        }
      }
    }
    results = Nest.fetch(sources)
    results.count.must_equal(2)
  end

  it "must be able to fetch resources for a single tag using more than one service" do
    sources = {
      'facebook' => {
        'tags' => {
          '100001' => %w(california),
          '100002' => %w(california)
        }
      },
      'twitter' => {
        'tags' => {
          '200001' => %w(california),
          '200002' => %w(california)
        }
      }
    }
    results = Nest.fetch(sources)
    results.count.must_equal(5)
  end

  it "must be able to paginate over results" do
    sources = {
      'facebook' => {
        'tags' => {
          '100001' => %w(california norcal cheeseburger),
          '100002' => %w(california)
        }
      },
      'twitter' => {
        'tags' => {
          '200001' => %w(california),
          '200002' => %w(california)
        }
      }
    }
    results = Nest.fetch(sources, :page => 1, :page_size => 5)
    results.count.must_equal(5)
    results = Nest.fetch(sources, :page => 2, :page_size => 5)
    results.count.must_equal(2)
  end

  it "must be able to sort results" do
    sources = {
      'facebook' => {
        'tags' => {
          '100001' => %w(california cheeseburger),
          '100002' => %w(california)
        }
      },
      'twitter' => {
        'tags' => {
          '200001' => %w(california),
          '200002' => %w(california)
        }
      }
    }
    ascending = Nest.fetch(sources, :sort_by => :uploaded_at, :sort_direction => 'asc').map { |r| r.created_at }
    descending = Nest.fetch(sources, :sort_by => :uploaded_at, :sort_direction => 'desc').map { |r| r.created_at }
    descending.to_a.must_equal(ascending.to_a.reverse)
  end

  it "must support time-bounded queries" do
    sources = {
      'facebook' => {
        'tags' => {
          '100001' => %w(california cheeseburger),
          '100002' => %w(california)
        }
      },
      'twitter' => {
        'tags' => {
          '200001' => %w(california),
          '200002' => %w(california)
        }
      }
    }
    results = Nest.fetch(sources, :since => Time.parse("2013-01-01 00:00:00").to_i)
    results.count.must_equal(4)
    results = Nest.fetch(sources, :until => Time.parse("2012-12-31 23:59:59").to_i)
    results.count.must_equal(2)
    results = Nest.fetch(sources, :since => Time.parse("2012-12-01 00:00:00").to_i, :until => Time.parse("2012-12-31 23:59:59").to_i)
    results.count.must_equal(1)
  end

  it "must be able to find all people tagged in the resources belonging to a nest" do
    sources = {
      'facebook' => {
        'tags' => {
          '100001' => %w(norcal cheeseburger)
        }
      }
    }
    people = Nest.find_tagged_people(sources)
    people.count.must_equal(2)
    people[0].first.must_equal('42')
    people[0].last.must_equal(2)
  end

  it "must be able to fetch resources belonging to a single album" do
    sources = {
      'facebook' => {
        'albums' => ['1']
      }
    }
    results = Nest.fetch(sources)
    results.count.must_equal(2)
  end


  it "must be able to fetch resources belonging to multiple albums" do
    sources = {
      'facebook' => {
        'albums' => ['1', '2']
      }
    }
    results = Nest.fetch(sources)
    results.count.must_equal(4)
  end

end
