require 'digest/md5'
require_relative '../test_helper'

describe Birdbox::Search::Resource do
  subject { Birdbox::Search::Resource }

  Birdbox::Search.configure do
    url 'http://localhost:9200'
    #logger STDERR, :debug => true
  end

  before do

    subject.index.delete
    subject.create_elasticsearch_index

    index_alias = Tire::Alias.new
    index_alias.name('resources')
    index_alias.index('resources_v1')
    index_alias.save

    @items = [ 
      subject.new(:id => Digest::MD5.hexdigest(['facebook', '1', '1'].join(':')), 
        :provider => "facebook", 
        :external_id => "1",
        :owner_uid => "123456", :owner_birdbox_nickname => "me", :album => '1', :title => "Purple #hashtag1 #hashtag2 sunset",
        :type => "photo", :description => "A purple sunset #hashtag1 off the coast of Isla Vista, CA",
        :url => "http://www.example.com/foo.jpg", :tags => %w(birdbox one), :removed => false, 
        :height => 640, :width => 480, :created_at => Time.now.utc),

      subject.new(:id => Digest::MD5.hexdigest(['facebook', '1', '2'].join(':')), 
        :provider => "facebook", 
        :external_id => "2", 
        :title => "No stone left unturned", :type => "photo", :album => '1',
        :owner_uid => "123456", :owner_birdbox_nickname => "me", :title => "",
        :url => "http://www.example.com/bar.jpg", :tags => %w(birdbox two), :removed => false,
        :height => 640, :width => 480, :created_at => Time.now.utc),

      subject.new(:id => Digest::MD5.hexdigest(['facebook', '2', '3'].join(':')), 
        :provider => "facebook", :external_id => "3",
        :title => "That looks delicious", :type => "photo", :album => '2',
        :url => "http://www.example.com/baz.jpg", :tags => %w(birdbox three), :removed => false,
        :height => 640, :width => 480, :created_at => Time.now.utc),

      subject.new(:id => Digest::MD5.hexdigest(['facebook', '2', '4'].join(':')), 
        :provider => "facebook", :external_id => "4",
        :title => "Tags good", :type => "photo", :url => "http://www.example.com/biz.jpg",
        :tags => ['birdbox-tokenizer', 'three'], :removed => false, :album => '2',
        :height => 640, :width => 480, :created_at => Time.now.utc),
    ]
    subject.index.import(@items)
    subject.index.refresh
  end
  
  it "must parse hashtags" do
    r = subject.first
    r.parse_hashtags.sort.must_equal(['hashtag1', 'hashtag2', 'birdbox', 'one'].sort)
  end

  it "must be persisted" do
    r = subject.first
    r.wont_be_nil
    r.persisted?.must_equal(true)
  end

  it "must be retrievable by id" do
    id = Digest::MD5.hexdigest(['facebook', '1', '1'].join(':'))
    r = subject.find(id)
    r.url.must_equal(@items.first.url) 
  end

  it "must be able to retrieve multiple ids" do
    ids = [
      Digest::MD5.hexdigest(['facebook', '1', '1'].join(':')),
      Digest::MD5.hexdigest(['facebook', '1', '2'].join(':'))
    ]
    r = subject.find(ids)
    r.size.must_equal(2)
  end

  it "must be searchable with a simple query" do
    r = subject.search("title:delicious")
    r.each { |item| (/delicious/i === item.title).must_equal(true) }
  end

  it "must be searchable with a block" do
    r = subject.search { |search|
      search.query { |query|
        query.match :tags, "three"
      }
    }
    r.size.must_equal(@items.count { |x| x.tags.include?("three") })
  end
  
  it "must not analyze/tokenize tags" do
    r = subject.search { |search|
      search.query { |query|
        query.term :tags, "birdbox"
        #query.string "tags:\"birdbox\""
        #query.terms :tags, ["birdbox"]
        #query.boolean { must { term :tags, "birdbox" }}
      }
    }
    r.size.must_equal(@items.count { |x| x.tags.include?("birdbox") })
  end

  it "must be able to search for multiple tags" do
    r = subject.search { |search|
      search.query { |query|
        query.terms :tags, ["one", "two"]
      }
    }
    r.size.must_equal(@items.count { |x| x.tags.include?("one") or x.tags.include?("two") })
  end

  it "must ensure that the resource is persisted correctly" do
    r = subject.new
    r.provider = 'facebook'
    r.external_id = '123'
    r.type = 'photo'
    r.url = 'http://www.example.com/cant-be-unseen.jpg'
    r.save

    result = subject.find(r.id)
    result.wont_be_nil
    result.created_at.wont_be_nil
  end

  it "must not update existing records when using the 'persist' method" do
    id = Digest::MD5.hexdigest(['facebook', '1', '1'].join(':'))
    r = subject.find(id)
    r.title = 'booya!'
    r.save.updated?.must_equal(false)
    subject.find(r.id).title.wont_equal(r.title)
  end

  it "must update existing records if the tags have changed" do
    id = Digest::MD5.hexdigest(['facebook', '1', '1'].join(':'))
    r = subject.find(id)
    r.title = 'booya!'
    r.tags << "danger"
    r.removed = true
    r.save.updated?.must_equal(true)
    newr = subject.find(r.id)
    newr.title.must_equal(r.title)
    newr.removed.must_equal(true)
  end

  it "must be able to return a unique list of tags for a user" do
    r = subject.find_unique_user_tags("123456")
    r.count.must_equal(3)
    r[0].last.must_equal(2)
    r[1].first.must_equal('one')
  end

  it "must be able to find resources by a tagged persons id" do
    r = subject.search { |search|
      search.query { |query|
        query.terms :people, ['facebook:123123']
      }
    }
    r.size.must_equal(@items.count { |x| x.people.include?("facebook:123123")})
  end

end
