require 'spec_helper'

response_fixture = <<-JMM
{
  "dbh": "12",
  "latitude": "37.7236055375669",
  "longitude": "-122.40420106151",
  "planttype": "Tree",
  "plotsize": "3x3",
  "qaddress": "690 Brussels St",
  "qcaretaker": "Private",
  "qlegalstatus": "Undocumented",
  "qsiteinfo": "Sidewalk: Curb side : Cutout",
  "qspecies": "Acer rubrum :: Red Maple",
  "siteorder": "1",
  "treeid": "96127",
  "xcoord": "6010969",
  "ycoord": "2091546"
}
JMM

describe TreePlanting do
  let(:api_response) { JSON.parse(response_fixture) }

  describe "#fancy_title" do
    it "returns the nicely formatted title message" do
      subject = TreePlanting.new(api_response)
      exp_title = "A new tree has been planted near you by the SF Department of Public Works at 690 Brussels St! It is a Acer Rubrum :: Red Maple and has been planted at a Sidewalk: Curb side : Cutout."
      expect(subject.fancy_title).to eq(exp_title)
    end
  end

  describe "#as_geojson_feature" do
    context "there is no location information" do
      it "returns nil" do
        subject = TreePlanting.new(api_response)
        allow(subject).to receive(:location) { nil }
        expect(subject.as_geojson_feature).to be_nil
      end
    end

    context "location information exists" do
      it "returns the proper geojson feature" do
        subject = TreePlanting.new(api_response)

        exp_geojson = {
          'id' => '96127',
          'type' => 'Feature',
          'properties' => api_response.merge('title' => subject.fancy_title),
          'geometry' => {
            'type' => 'Point',
            'coordinates' => [-122.40420106151, 37.7236055375669]
          }
        }
        expect(subject.as_geojson_feature).to eq(exp_geojson)
      end
    end
  end
end
