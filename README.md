# Birdbox::Search

An abstraction of the Elasticsearch API powering Birdbox Search.

## Installation

First, you need a running _Elasticsearch_ server. 

     wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.0.deb
     sudo dpkg -i elasticsearch-0.90.0.deb
     sudo service elasticsearch start
     
Make sure that you update the elasticsearch-0.90.0.deb to the most recent version. Also, if you're using redhat, you will need to use alien to convert it.

On a Mac, you can also use _Homebrew_:

    $ brew install elasticsearch


Next, include the gem in your application by adding the following line to your Gemfile (should already be done, but go ahead and check):

    gem 'birdbox-search', :git => "git@github.com:BirdBox/birdbox-search.git"

And then execute:

    $ bundle install
