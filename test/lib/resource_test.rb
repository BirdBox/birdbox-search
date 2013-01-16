require_relative '../test_helper'

describe Birdbox::Search::Resource do
  subject { Birdbox::Search::Resource }

  before do
    subject.index.delete
    subject.create_elasticsearch_index
    @items = [ 
      subject.new(:id => 'fb:1', :provider => "facebook", :owner_uid => "123456", 
        :owner_nickname => "me", :title => "Purple sunset", :type => "photo", 
        :description => "A purple sunset off the coast of Isla Vista, CA",
        :url => "http://www.example.com/foo.jpg", :tags => %w(birdbox one),
        :height => 640, :width => 480, :created_at => Time.now.utc),

      subject.new(:id => 'fb:2', :title => "No stone left unturned", :type => "photo",
        :url => "http://www.example.com/bar.jpg", :tags => %w(birdbox two)),

      subject.new(:id => 'fb:3', :title => "That looks delicious", :type => "photo",
        :url => "http://www.example.com/baz.jpg", :tags => %w(birdbox three)),

      subject.new(:id => 'fb:4', :title => "Tags good", :type => "photo", 
        :url => "http://www.example.com/biz.jpg", :tags => ['birdbox-tokenizer', 'three'])
    ]
    subject.index.import(@items)
    subject.index.refresh
  end

  it "must be persisted" do
    r = subject.first
    r.wont_be_nil
    r.persisted?.must_equal(true)
  end

  it "must be retrievable by id" do
    r = subject.find('fb:1')
    r.url.must_equal(@items.first.url) 
  end

  it "must be able to retrieve multiple ids" do
    r = subject.find(['fb:1', 'fb:2'])
    r.size.must_equal(2)
    r.first.url.must_equal(@items[1].url)
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

end
