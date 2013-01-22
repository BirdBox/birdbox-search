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
    @items = [ 
      subject.new(:id => 'facebook:1', :provider => "facebook", :external_id => "1",
        :owner_uid => "123456", :owner_nickname => "me", :title => "Purple #hashtag1 #hashtag2 sunset",
        :type => "photo", :description => "A purple sunset #hashtag1 off the coast of Isla Vista, CA",
        :url => "http://www.example.com/foo.jpg", :tags => %w(birdbox one),
        :height => 640, :width => 480, :created_at => Time.now.utc),

      subject.new(:id => 'facebook:2', :provider => "facebook", :external_id => "2", 
        :title => "No stone left unturned", :type => "photo",
        :url => "http://www.example.com/bar.jpg", :tags => %w(birdbox two)),

      subject.new(:id => 'facebook:3', :provider => "facebook", :external_id => "3",
        :title => "That looks delicious", :type => "photo",
        :url => "http://www.example.com/baz.jpg", :tags => %w(birdbox three)),

      subject.new(:id => 'facebook:4', :provider => "facebook", :external_id => "4",
        :title => "Tags good", :type => "photo", :url => "http://www.example.com/biz.jpg",
        :tags => ['birdbox-tokenizer', 'three'])
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
    r = subject.find('facebook:1')
    r.url.must_equal(@items.first.url) 
  end

  it "must be able to retrieve multiple ids" do
    r = subject.find(['facebook:1', 'facebook:2'])
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
    result = subject.find([r.provider, r.external_id].join(':'))
    result.wont_be_nil
    result.created_at.wont_be_nil
  end

  it "must not update existing records when using the 'persist' method" do
    r = subject.find('facebook:1')
    r.title = 'booya!'
    r.save.updated?.must_equal(false)
    subject.find(r.id).title.wont_equal(r.title)
  end

  it "must update existing records if the tags have changed" do
    r = subject.find('facebook:1')
    r.title = 'booya!'
    r.tags << "danger"
    r.save.updated?.must_equal(true)
    subject.find(r.id).title.must_equal(r.title)
  end

end
