require "bundler/gem_tasks"
require "rake/testtask"

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "lib/birdbox-search"
  t.test_files = FileList["test/lib/*.rb"]
  t.verbose = true
end


task :build do
  system "gem build birdbox-search.gemspec"
end

