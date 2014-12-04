require File.join(File.dirname(__FILE__), '..', 'lib', 'app.rb')
require 'sinatra'
require 'rack/test'
require 'vcr'

# Require any support files (i.e. custom matchers)
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each{ |f| require f }

# setup test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
  Sinatra::Application
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.debug_logger
end


RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include CustomJsonMatchers
end
