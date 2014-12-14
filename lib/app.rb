Dir[File.join(File.dirname(__FILE__), 'adapters', '*.rb')].each { |file| require file }
require File.join(File.dirname(__FILE__), 'hash_cache')
require 'faraday'
require 'sinatra'
require 'geocoder'
require 'json'

Geocoder.configure({
  :always_raise => [Geocoder::OverQueryLimitError],
})

get '/' do
	content_type :html
	response = '<a href="'+request.url+'tree-planting">' + request.url + 'tree-planting</a><br/>'
	response << '<a href="'+request.url+'tow-away-zones">' + request.url + 'tow-away-zones</a><br />'
  response << '<a href="'+request.url+'street-use-permits">' + request.url + 'street-use-permits</a><br />'
  response << '<a href="'+request.url+'food-truck-permits">' + request.url + 'food-truck-permits</a><br />'
end

get '/tree-planting' do
  url = URI('http://data.sfgov.org/resource/tkzw-k3nq.json')
  url.query = Faraday::Utils.build_query(
    '$order' => 'plantdate DESC',
    '$limit' => 100,
    '$where' => "treeid IS NOT NULL"+
    " AND permitnotes IS NOT NULL"+
    " AND latitude IS NOT NULL"+
    " AND longitude IS NOT NULL"+
    " AND plantdate > '#{(DateTime.now - 365).iso8601}'"
  )
  connection = Faraday.new(url: url.to_s)
  response = connection.get
  collection = JSON.parse(response.body)
  features = collection.map do |record|
    {
      'id' => record['treeid'],
      'type' => 'Feature',
      'properties' => record.merge('title' => record['permitnotes']),
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          record['longitude'].to_f,
          record['latitude'].to_f
        ]
      }
    }
  end

  content_type :json
  JSON.pretty_generate('type' => 'FeatureCollection', 'features' => features)
end

get '/tow-away-zones' do
  url = URI('http://data.sfgov.org/resource/cqn5-muyy.json')
  url.query = Faraday::Utils.build_query(
	  '$order' => 'updatedat DESC',
	  '$limit' => 100,
	  '$where' => "mta_status_code = 'Approved'"+
	  " AND dbi_application_number IS NOT NULL"+
	  " AND frontage IS NOT NULL"+
	  " AND fromaddress IS NOT NULL"+
	  " AND toaddress IS NOT NULL"+
	  " AND streetname IS NOT NULL"+
	  " AND updatedat > '#{(DateTime.now - 7).iso8601}'"
  )
  connection = Faraday.new(url: url.to_s)
  response = connection.get
  collection = JSON.parse(response.body)
  features = collection.map do |record|
	  {
		  'id' => record['dbi_application_number'],
		  'type' => 'Feature',
			  'properties' => record.merge(
				  'title' => record['frontage'],
				  ),
			  'geometry' => {
			  'type' => 'Point',
			  'coordinates' => [
				  record['longitude'].to_f,
				  record['latitude'].to_f
		  ]
		  }
	  }
  end

  content_type :json
  JSON.pretty_generate('type' => 'FeatureCollection', 'features' => features)
end

geocoder_cache = HashCache.new

get '/street-use-permits' do
  connection = Faraday.new(:url => StreetUsePermit.query_url)

  begin
    # Query the data.sfgov.org endpoint
    response = connection.get
    # Parse the json response
    collection = JSON.parse(response.body)

    # Build our features
    features = collection.map do |record|
      StreetUsePermit.new(record, geocoder_cache).as_geojson_feature
    end.compact

    content_type :json
    JSON.pretty_generate('type' => 'FeatureCollection', 'features' => features)

  rescue Geocoder::OverQueryLimitError => e
    [503, "Error with geocoding service"]
  end

end

get '/food-truck-permits' do
  connection = Faraday.new(:url => FoodTruckPermit.query_url)

  # Query the data.sfgov.org endpoint
  response = connection.get
  # Parse the json response
  collection = JSON.parse(response.body)

  # Build our features
  features = collection.map do |record|
    FoodTruckPermit.new(record).as_geojson_feature
  end.compact

  content_type :json
  JSON.generate('type' => 'FeatureCollection', 'features' => features)
end
