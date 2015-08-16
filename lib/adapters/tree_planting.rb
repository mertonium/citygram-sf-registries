class TreePlanting < SocrataBase
  SOCRATA_ENDPOINT = 'http://data.sfgov.org/resource/tkzw-k3nq.json'

# Text from https://github.com/citygram/citygram-services/issues/21
TITLE_TEMPLATE = <<-CFA.gsub(/\s*\n/, ' ').chomp(' ')
A new tree has been planted near you by the SF Department of Public Works
at %{address}! It is a %{species} and has been planted in a %{site_info}.
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
      :species => humanize_species(@record['qspecies']),
      :site_info => humanize_site_info(@record['qsiteinfo']),
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

  private

  def humanize_species(qspecies)
    species_pieces = qspecies.split('::').map(&:strip)

    if species_pieces.length == 1
      # When there is only one piece to the name, it's usually "tree".
      species_pieces[0].downcase.gsub(/\(s\)/,'')
    else
      "#{species_pieces[1]} (#{species_pieces[0]})"
    end
  end

  def humanize_site_info(qsiteinfo)
    case qsiteinfo
    when 'Sidewalk: Curb side : Cutout'
      'curbside sidewalk cutout'
    when 'Sidewalk: Curb side : Yard'
      'curbside yard'
    when 'Sidewalk: Property side : Cutout'
      'property-side sidewalk cutout'
    when 'Median : Cutout'
      'median cutout'
    when 'Front Yard : Cutout'
      'front yard cutout'
    when 'Front Yard : Yard'
      'front yard'
    else
      qsiteinfo
    end
  end
end
