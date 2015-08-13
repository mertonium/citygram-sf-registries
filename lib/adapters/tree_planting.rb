class TreePlanting < SocrataBase
  SOCRATA_ENDPOINT = 'http://data.sfgov.org/resource/tkzw-k3nq.json'

# Text from https://github.com/citygram/citygram-services/issues/21
TITLE_TEMPLATE = <<-CFA.gsub(/\s*\n/, ' ').chomp(' ')
A new tree has been planted near you by the SF Department of Public Works
at %{address}! It is a %{species} and has been planted at a %{site_info}.
CFA

  def self.query_url
    url = URI(SOCRATA_ENDPOINT)

    url.query = Faraday::Utils.build_query(
      '$order' => 'plantdate DESC',
      '$limit' => 100,
      '$where' => "treeid IS NOT NULL"+
      " AND permitnotes IS NOT NULL"+
      " AND latitude IS NOT NULL"+
      " AND longitude IS NOT NULL"+
      " AND plantdate > '#{(DateTime.now - 365).iso8601}'"
    )

    url.to_s
  end

  def fancy_title
    title_pieces = {
      :address => Utils.titleize(@record['qaddress']),
      :species => Utils.titleize(@record['qspecies']),
      :site_info => @record['qsiteinfo'],
    }

    TITLE_TEMPLATE % title_pieces
  end

  def as_geojson_feature
    return nil if location.nil?

    {
      'id' => @record['treeid'],
      'type' => 'Feature',
      'properties' => @record.merge('title' => fancy_title),
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          location['longitude'].to_f,
          location['latitude'].to_f,
        ]
      }
    }
  end

  def location
    {
      'longitude' => @record['longitude'],
      'latitude' => @record['latitude'],
    }
  end
end
