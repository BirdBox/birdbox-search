require 'digest/md5'
require_relative '../test_helper'

describe Birdbox::Search::Resource do

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
  

  it "must parse hashtags" do
    id = Digest::MD5.hexdigest(['facebook', '1'].join(':'))
    r = Resource.find(id)
    r.parse_hashtags.sort.must_equal(%w(california sunset).sort)
  end


  it "must be persisted" do
    r = Resource.first
    r.wont_be_nil
    r.persisted?.must_equal(true)
  end


  it "must be retrievable by id" do
    id = Digest::MD5.hexdigest(['facebook', '1'].join(':'))
    r = Resource.find(id)
    r.url.must_equal(Fixtures.resources.first.url) 
  end


  it "must be able to retrieve multiple ids" do
    ids = [
      Digest::MD5.hexdigest(['facebook', '1'].join(':')),
      Digest::MD5.hexdigest(['facebook', '2'].join(':'))
    ]
    r = Resource.find(ids)
    r.size.must_equal(2)
  end


  it "must be searchable with a simple query" do
    r = Resource.search("title:delicious")
    r.each { |item| (/delicious/i === item.title).must_equal(true) }
  end


  it "must be searchable with a block" do
    r = Resource.search { |search|
      search.query { |query|
        query.match :tags, "california"
      }
    }
    r.size.must_equal(Fixtures.resources.count { |x| x.tags.include?("california") })
  end

  
  it "must not analyze/tokenize tags" do
    r = Resource.search { |search|
      search.query { |query|
        query.term :tags, "norcal"
        #query.string "tags:\"birdbox\""
        #query.terms :tags, ["birdbox"]
        #query.boolean { must { term :tags, "birdbox" }}
      }
    }
    r.size.must_equal(Fixtures.resources.count { |x| x.tags.include?("norcal") })
  end


  it "must be able to search for multiple tags" do
    r = Resource.search { |search|
      search.query { |query|
        query.terms :tags, %w(california norcal)
      }
    }
    r.size.must_equal(Fixtures.resources.count { |x| x.tags.include?("california") or x.tags.include?("norcal") })
  end


  it "must ensure that the resource is persisted correctly" do
    r = Resource.new
    r.provider = 'facebook'
    r.external_id = '123'
    r.type = 'photo'
    r.url = 'http://www.example.com/cant-be-unseen.jpg'
    r.save

    result = Resource.find(r.id)
    result.wont_be_nil
    result.created_at.wont_be_nil
  end


  it "must not update existing records when using the 'save' method" do
    id = Digest::MD5.hexdigest(['facebook', '1'].join(':'))
    r = Resource.find(id)
    r.title = 'booya!'
    r.save
    r.updated?.must_equal(false)
    Resource.find(r.id).title.wont_equal(r.title)
  end


  it "must update existing records if the tags have changed" do
    id = Digest::MD5.hexdigest(['facebook', '1'].join(':'))
    r = Resource.find(id)
    r.title = 'booya!'
    r.tags << "danger"
    r.removed = true
    r.save
    r.updated?.must_equal(true)
    newr = Resource.find(r.id)
    newr.title.must_equal(r.title)
    newr.removed.must_equal(true)
  end


  it "must be able to return a unique list of tags for a user" do
    r = Resource.find_unique_user_tags("200002")
    r.count.must_equal(2)
    r[0].first.must_equal('california')
    r[0].last.must_equal(2)
  end


  it "must be able to find resources by a tagged persons id" do
    s = Resource.search do 
          query { all }
          filter :term, 'people.id' => '22'
      end

    s.results.count.must_equal(
      Fixtures.resources.count do |r|
        r.people.map { |p| p[:id] }.include?('22')
      end
     )
  end

  
  it "must be able to report new album count" do
    new_resource = Resource.new(:id => Digest::MD5.hexdigest(['facebook', '1'].join(':')), 
      :provider => "facebook", 
      :external_id => "1234-44",
      :owner_uid => "123456",
      :owner_birdbox_nickname => "me", 
      :albums => [
        { :id => '44-44', :name => 'new' }
      ],
      :title => "Purple #hashtag1 #hashtag2 sunset",
      :type => "photo",
      :description => "A purple sunset #hashtag1 off the coast of Isla Vista, CA",
      :url => "http://www.example.com/foo.jpg",
      :tags => %w(birdbox one),
      :removed => false, 
      :download_height => 640,
      :download_width => 480,
      :created_at => Time.now.utc)
    new_resource.save
    new_resource.new_albums.count.must_equal(1)
  end
  

  it "must be able to add and remove albums from a resource" do
    new_resource = Resource.new(:id => Digest::MD5.hexdigest(['facebook', '1'].join(':')), 
      :provider => "facebook", 
      :external_id => "1",
      :owner_uid => "123456",
      :owner_birdbox_nickname => "me", 
      :albums => [
        { :id => '2', :name => 'two' }
      ],
      :title => "Purple #hashtag1 #hashtag2 sunset",
      :type => "photo",
      :description => "A purple sunset #hashtag1 off the coast of Isla Vista, CA",
      :url => "http://www.example.com/foo.jpg",
      :tags => %w(birdbox one),
      :removed => false, 
      :download_height => 640,
      :download_width => 480,
      :created_at => Time.now.utc)
    new_resource.save
    new_resource.new_albums.count.must_equal(1)
    r = Resource.find(Digest::MD5.hexdigest(['facebook', '1'].join(':')))
    r.albums.count.must_equal(2)
    r.remove_albums = true
    r.albums = [{ :id => '2', :name => 'two' }]
    r.save
    r.albums.count.must_equal(1)
    r.removed.must_equal(false)
    # no more albums
    r.albums = [{ :id => '1', :name => 'one' }]
    r.save
    r.albums.count.must_equal(0)
    r.removed.must_equal(true)
    # here i am again
    r.remove_albums = false
    r.albums = [{ :id => '1', :name => 'one' }]
    r.save
    r.albums.count.must_equal(1)
    r.removed.must_equal(false)
  end

end
