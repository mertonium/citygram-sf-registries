require 'spec_helper'

describe "street-use-permits" do
  context "the happy path" do
    it "returns valid geojson" do
      VCR.use_cassette('street_use_permit_happy_path', :record => :once, :match_requests_on => [:host, :path]) do
        get '/street-use-permits'
        expect(last_response.body).to be_valid_geojson
      end
    end
  end

  context "the geocoder is over it's api limit" do
    it "returns a 503 status"
  end
end
