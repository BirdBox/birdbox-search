# Birdbox::Search

An abstraction of the Elasticsearch API powering Birdbox Search.

## Installation

First, you need a running _Elasticsearch_ server. Thankfully, it's easy. Let's define easy:

    $ curl -k -L -o elasticsearch-0.20.2.tar.gz http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.20.2.tar.gz
    $ tar -zxvf elasticsearch-0.20.2.tar.gz
    $ ./elasticsearch-0.20.2/bin/elasticsearch -f

On a Mac, you can also use _Homebrew_:

    $ brew install elasticsearch


Next, include the gem in your application by adding the following line to your Gemfile:

    gem 'birdbox-search', :git => "git@github.com:BirdBox/birdbox-search.git"

And then execute:

    $ bundle

## Usage

```ruby
  # Necessary because the gem is installed via git.
  require 'bundler'
  Bundler.setup

  require 'birdbox-search'

  # Create an alias to save yourself some typing.
  Resource = Birdbox::Search::Resource

  # CAREFUL! Deletes all data in the 'resources' index.
  Resource.index.delete

  # Create a single record.
  Resource.create(:id => 1, :title => "Purple sunset", :type => "photo",
    :url => "http://www.example.com/foo.jpg", :tags => %w(birdbox one))

  # Create several records using the more efficient bulk update API.
  Resource.index.import([
    Resource.new(:id => 2, :title => "No stone left unturned", :type => "photo", 
      :url => "http://www.example.com/bar.jpg", :tags => %w(birdbox two)),
    Resource.new(:id => 3, :title => "That looks delicious", :type => "photo", 
      :url => "http://www.example.com/baz.jpg", :tags => %w(birdbox three))
  ])

  # Force the index to be refreshed immediately. Doing this too often will
  # cause performance issues.
  Resource.index.refresh

  # Find a resource by id.
  puts Resource.find(1).url

  # The find method also accepts multiple parameters, returning an array.
  Resource.find([1, 2, 3]).each { |r|
    puts r.url
  }
  
  # Perform a simple search.
  Resource.search("title:delicious").each { |r|
    if (/delicious/i === r.title)
      puts r.url
    end
  }

  # A more complicated search using a block.
  results = Resource.search { |search|
    search.query { |query|
      query.match :type, "photo"
    }
  }
```

This gem is basically just a wrapper around the excellent [Tire](https://github.com/karmi/tire) gem.
The [annotated documentation](http://karmi.github.com/tire) of that gem is very useful.

