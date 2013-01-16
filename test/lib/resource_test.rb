require_relative '../test_helper'

describe Birdbox::Search::Resource do
  subject { Birdbox::Search::Resource }

  before do
    subject.index.delete
    @items = [ 
      subject.new(:id => 1, :title => "Purple #hashtag1 sunset", :type => "photo", :url => "http://www.example.com/foo.jpg", :tags => %w(birdbox one)),
      subject.new(:id => 2, :title => "No stone #hashtag2 left unturned", :type => "photo", :url => "http://www.example.com/bar.jpg", :tags => %w(birdbox two)),
      subject.new(:id => 3, :title => "That #hashtag1 looks delicious", :type => "photo", :url => "http://www.example.com/baz.jpg", :tags => %w(birdbox three)),
      subject.new(:id => 4, :title => "Tags #hashtag2 good", :type => "photo", :url => "http://www.example.com/biz.jpg", :tags => %w(birdbox-tokenizer three))
    ]
    subject.index.import(@items)
    subject.index.refresh
  end
  
  it "must parse hashtags" do
    r = subject.first
    r.parse_hashtags.must_equal(['#hashtag1'])
  end

  it "must be persisted" do
    r = subject.first
    r.wont_be_nil
    r.persisted?.must_equal(true)
    r.url.must_equal(@items.first.url)
  end

  it "must be retrievable by id" do
    r = subject.find(1)
    r.url.must_equal(@items.first.url) 
  end

  it "must be able to retrieve multiple ids" do
    r = subject.find([2, 3])
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
    puts r.inspect
    r.size.must_equal(@items.count { |x| x.tags.include?("three") })
  end
  
  it "must not be tokenized on tags" do
    r = subject.search { |search|
      search.query { |query|
        query.match :tags, "birdbox"
      }
    }
    puts r.inspect
    r.size.must_equal(@items.count { |x| x.tags.include?("birdbox") })
  end

end
