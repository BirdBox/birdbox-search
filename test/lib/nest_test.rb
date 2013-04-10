require 'time'
require_relative '../test_helper'

describe Birdbox::Search::Nest do
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

    Fixtures.resources.each { |r| r.save }
    Resource.index.refresh
  end
  
  it "should raise an Error for bad unitl param" do
    sources = {
      'facebook' => {'albums' => %w(1)}
    }
    proc { Nest.fetch(sources, :since => '1234') }.must_raise ArgumentError
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
    results = Nest.fetch(sources, :until => Time.parse("2011-01-01 00:00:00"))
    results.count.must_equal(0)
    results = Nest.fetch(sources, :since => Time.parse("2011-01-01 00:00:00"))
    results.count.must_equal(8)
    results = Nest.fetch(sources, :since => Time.parse("2013-01-01 00:00:00"))
    results.count.must_equal(5)
    results = Nest.fetch(sources, :until => Time.parse("2012-12-31 23:59:59"))
    results.count.must_equal(3)
    results = Nest.fetch(sources, :since => Time.parse("2012-11-15 00:00:00"), :until => Time.parse("2012-11-15 23:59:59"))
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
  
  it "must be able to paginate duplicate updated at consistently" do
    Resource.index.delete
    Resource.create_elasticsearch_index
    index_alias = Tire::Alias.new
    index_alias.name('resources')
    index_alias.index('resources_v1')
    index_alias.save
    # TODO @kcbigring
    # Serialization of timestamp is losing miliseconds on import so figure out how to fix that
    # Currently, import is NOT used in the app (only testing), so table
    # Resource.index.import(Fixtures.ordered_resources)
    Fixtures.ordered_resources.each do |r|
      r.save
    end
    Resource.index.refresh
    
    sources = {
      'facebook' => {
        'albums' => %w(1)
      },
      'instagram' => {
        'tags' => {
          '200001' => %w(california)
        }
      }
    }
    results = Nest.fetch(sources, :page_size => 2)
    results.count.must_equal(2)
    results[0].external_id.must_equal('4')
    results[0].provider.must_equal('instagram')
    results[1].external_id.must_equal('3')
    results[1].provider.must_equal('instagram')
    
    results = Nest.fetch(sources, :page_size => 2, :until => results[1].uploaded_at)
    results.count.must_equal(2)
    results[0].external_id.must_equal('2')
    results[0].provider.must_equal('instagram')
    results[1].external_id.must_equal('1')
    results[1].provider.must_equal('instagram')

    results = Nest.fetch(sources, :page_size => 2, :until => results[1].uploaded_at)
    results.count.must_equal(2)
    results[0].external_id.must_equal('4')
    results[0].provider.must_equal('facebook')
    results[1].external_id.must_equal('3')
    results[1].provider.must_equal('facebook')
    
    # Reverse the sort order... weird use case but make sure it works
    # In this case we will be unbounding the lower end so will get resources 0, 1, and 2
    results = Nest.fetch(sources, :until => results[1].uploaded_at, :sort_direction => 'asc')
    results.count.must_equal(3)
    results[2].external_id.must_equal('2')
    results[2].provider.must_equal('facebook')
    results[1].external_id.must_equal('1')
    results[1].provider.must_equal('facebook')
    results[0].external_id.must_equal('0')
    results[0].provider.must_equal('facebook')
    
    # Bound upper and lower
    results = Nest.fetch(sources, :until => results[2].uploaded_at, :since => results[0].uploaded_at)
    results.count.must_equal(1)
    results[0].external_id.must_equal('1')
    results[0].provider.must_equal('facebook')
    
    results = Nest.fetch(sources, :page_size => 2, :until => results[0].uploaded_at)
    results.count.must_equal(1)
    results[0].external_id.must_equal('0')
    results[0].provider.must_equal('facebook')
  end
  
  it "must be able to paginate duplicate updated at consistently asc" do
    Resource.index.delete
    Resource.create_elasticsearch_index
    index_alias = Tire::Alias.new
    index_alias.name('resources')
    index_alias.index('resources_v1')
    index_alias.save
    Fixtures.ordered_resources.each do |r|
      r.save
    end
    Resource.index.refresh
    
    sources = {
      'facebook' => {
        'albums' => %w(1)
      },
      'instagram' => {
        'tags' => {
          '200001' => %w(california)
        }
      }
    }
    results = Nest.fetch(sources, :page_size => 2, :sort_direction => 'asc')
    results.count.must_equal(2)
    results[0].external_id.must_equal('0')
    results[0].provider.must_equal('facebook')
    results[1].external_id.must_equal('1')
    results[1].provider.must_equal('facebook')
    
    results = Nest.fetch(sources, :page_size => 2, :sort_direction => 'asc', :since => results[1].uploaded_at)
    results.count.must_equal(2)
    results[0].external_id.must_equal('2')
    results[0].provider.must_equal('facebook')
    results[1].external_id.must_equal('3')
    results[1].provider.must_equal('facebook')

    results = Nest.fetch(sources, :page_size => 2, :sort_direction => 'asc', :since => results[1].uploaded_at)
    results.count.must_equal(2)
    results[0].external_id.must_equal('4')
    results[0].provider.must_equal('facebook')
    results[1].external_id.must_equal('1')
    results[1].provider.must_equal('instagram')

    results = Nest.fetch(sources, :page_size => 2, :sort_direction => 'asc', :since => results[1].uploaded_at)
    results.count.must_equal(2)
    results[0].external_id.must_equal('2')
    results[0].provider.must_equal('instagram')
    results[1].external_id.must_equal('3')
    results[1].provider.must_equal('instagram')

    results = Nest.fetch(sources, :page_size => 2, :sort_direction => 'asc', :since => results[1].uploaded_at)
    results.count.must_equal(1)
    results[0].external_id.must_equal('4')
    results[0].provider.must_equal('instagram')
  end
  
end
