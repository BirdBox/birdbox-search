require_relative '../test_helper'
describe Birdbox::Search do
  it "must be defined" do
    Birdbox::Search::VERSION.wont_be_nil
  end
end
