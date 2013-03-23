require 'digest/md5'
require 'minitest/autorun'
require File.expand_path('../../lib/birdbox-search.rb', __FILE__)


module Fixtures
  def self.resources
    [
      Resource.new(:id => Digest::MD5.hexdigest('facebook:1'),
        :provider => "facebook",
        :external_id => "1",
        :owner_uid => "100001",
        :owner_birdbox_nickname => "alice", 
        :title => "Purple sunset",
        :type => "photo",
        :description => "A purple sunset off the coast of Isla Vista, CA",
        :url => "http://www.example.com/isla_vista.jpg",
        :tags => [ ],
        :albums => [
          { :id => '1', :name => 'one' }
        ],
        :people => [
          { :id => '22', :name => 'Rickey Henderson' },
          { :id => '34', :name => 'Dave Steward' }
        ],
        :height => 640,
        :width => 480,
        :removed => false,
        :created_at => Time.parse("2013-01-01 00:02:14"),
        :updated_at => Time.parse("2013-01-01 00:02:14"),
        :uploaded_at => Time.parse("2013-01-01 00:02:14"), 
        :taken_at => Time.parse("2013-01-01 00:02:14")),

      Resource.new(:id => Digest::MD5.hexdigest('facebook:2'),
        :provider => "facebook",
        :external_id => "2",
        :owner_uid => "100001",
        :owner_birdbox_nickname => "alice",
        :title => "That looks delicious",
        :type => "photo", 
        :description => "That's the best looking cheesebuger I've seen in quite a while",
        :url => "http://www.example.com/cheeseburger.jpg",
        :tags => [ ],
        :people => [
          { :id => '22', :name => 'Rickey Henderson' },
          { :id => '42', :name => 'Dave Henderson' }
        ],
        :albums => [
          { :id => '1', :name => 'one' }
        ],
        :height => 640, :width => 480,
        :removed => false,
        :created_at => Time.parse("2013-01-18 15:26:42"),
        :updated_at => Time.parse("2013-01-18 15:26:42"),
        :uploaded_at => Time.parse("2013-01-18 15:26:42"), 
        :taken_at => Time.parse("2013-01-18 15:26:42")),

      Resource.new(:id => Digest::MD5.hexdigest('facebook:3'),
        :provider => "facebook",
        :external_id => "3",
        :owner_uid => "100002", 
        :owner_birdbox_nickname => "bob", 
        :title => "Bidwell Park",
        :type => "photo", 
        :description => "Enjoying a long hike in Bidwell Park.",
        :url => "http://www.example.com/bidwell.jpg",
        :tags => [ ],
        :albums => [
          { :id => '2', :name => 'two' }
        ],
        :people => [
          { :id => '22', :name => 'Rickey Henderson' },
          { :id => '43', :name => 'Dennis Eckersley' }
        ],
        :height => 640,
        :width => 480,
        :removed => false,
        :created_at => Time.parse("2013-01-10 22:34:07"),
        :updated_at => Time.parse("2013-01-10 22:34:07"),
        :uploaded_at => Time.parse("2013-01-10 22:34:07"), 
        :taken_at => Time.parse("2013-01-10 22:34:07")),

      Resource.new(:id => Digest::MD5.hexdigest('facebook:4'),
        :provider => "facebook",
        :external_id => "4",
        :owner_uid => "100001", 
        :owner_birdbox_nickname => "alice", 
        :title => "Redwoods in Arcata",
        :type => "photo", 
        :description => "Damn, that's a lot of trees.",
        :url => "http://www.example.com/arcata.jpg",
        :tags => [ ],
        :albums => [
          { :id => '2', :name => 'two' }
        ],
        :people => [
          { :id => '42', :name => 'Dave Henderson' }
        ],
        :height => 640,
        :width => 480,
        :removed => false,
        :created_at => Time.parse("2013-02-02 12:54:15"),
        :updated_at => Time.parse("2013-02-02 12:54:15"),
        :uploaded_at => Time.parse("2013-02-02 12:54:15"), 
        :taken_at => Time.parse("2013-02-02 12:54:15")),

      Resource.new(:id => Digest::MD5.hexdigest('instagram:1'),
        :provider => "instagram",
        :external_id => "1",
        :owner_uid => "200001",
        :owner_birdbox_nickname => "alice",
        :title => "The Golden Gate",
        :type => "photo",
        :description => "Look at that, not a cloud in the sky.",
        :url => "http://www.example.com/golden_gate.jpg",
        :tags => %w(california),
        :height => 640,
        :width => 480,
        :removed => false,
        :created_at => Time.parse("2013-01-02 13:04:11"),
        :updated_at => Time.parse("2013-01-02 13:04:11"),
        :uploaded_at => Time.parse("2013-01-02 13:04:11"), 
        :taken_at => Time.parse("2013-01-02 13:04:11")),

      Resource.new(:id => Digest::MD5.hexdigest('instagram:2'),
        :provider => "instagram",
        :external_id => "2",
        :owner_uid => "200002",
        :owner_birdbox_nickname => "bob",
        :title => "The Golden Gate",
        :type => "photo",
        :description => "Look at that, not a cloud in the sky.",
        :url => "http://www.example.com/golden_gate.jpg",
        :tags => %w(california),
        :height => 640,
        :width => 480,
        :removed => false,
        :created_at => Time.parse("2012-12-05 9:23:56"),
        :updated_at => Time.parse("2012-12-05 9:23:56"),
        :uploaded_at => Time.parse("2012-12-05 9:23:56"), 
        :taken_at => Time.parse("2012-12-05 9:23:56")),

      Resource.new(:id => Digest::MD5.hexdigest('instagram:3'),
        :provider => "instagram",
        :external_id => "3",
        :owner_uid => "200002",
        :owner_birdbox_nickname => "bob",
        :title => "Hearst Castle",
        :type => "photo",
        :description => "Damn, nice crib.",
        :url => "http://www.example.com/hearst_castle.jpg",
        :tags => %w(california),
        :height => 640,
        :width => 480,
        :removed => false,
        :created_at => Time.parse("2012-11-15 16:12:41"),
        :updated_at => Time.parse("2012-11-15 16:12:41"),
        :uploaded_at => Time.parse("2012-11-15 16:12:41"), 
        :taken_at => Time.parse("2012-11-15 16:12:41")),

      Resource.new(:id => Digest::MD5.hexdigest('instagram:4'),
        :provider => "instagram",
        :external_id => "4",
        :owner_uid => "200002",
        :owner_birdbox_nickname => "bob",
        :title => "Avenue of the Giants",
        :type => "photo",
        :description => "Big trees",
        :url => "http://www.example.com/avenue_of_the_giants.jpg",
        :tags => %w(norcal),
        :height => 640,
        :width => 480,
        :removed => false,
        :created_at => Time.parse("2012-11-15 11:55:24"),
        :updated_at => Time.parse("2012-11-15 11:55:24"),
        :uploaded_at => Time.parse("2012-11-15 11:55:24"),
        :taken_at => Time.parse("2012-11-15 11:55:24")),
    ]

  end
end

