# frozen_string_literal: true

require 'mockserver-client'

class Mock
  include MockServer
  include MockServer::Model::DSL

  def nominatim
    client = MockServer::MockServerClient.new('localhost', 1090)
    expectation = expectation do |expectation|
      expectation.request do |request|
        request.method = 'GET'
        request.path = '/nominatim/v1/search'
        request.query_string_parameters = [
          parameter('country', 'nl'),
          parameter('town', ''),
          parameter('addressdetails', '1'),
          parameter('city', ''),
          parameter('format', 'json'),
          parameter('polygon', '0'),
          parameter('postalcode', ''),
          parameter('street', ''),
          parameter('limit', '1'),
          parameter('state', ''),
          parameter('extratags', '1'),
          parameter('namedetails', '1'),
          parameter('key', 'secret')
        ]
      end

      expectation.response do |response|
        response.status_code = 200
        response.headers << header('Content-Type', 'application/json; charset=utf-8')
        response.body = [
          {
            place_id: '144005013',
            licence: 'Data © OpenStreetMap contributors, ODbL 1.0. '\
                       'http://www.openstreetmap.org/copyright',
            osm_type: 'relation',
            osm_id: '2323309',
            boundingbox: %w[
                11.777
                53.7253321
                -70.2695875
                7.2274985
              ],
            lat: '52.5001698',
            lon: '5.7480821',
            display_name: 'The Netherlands',
            place_rank: '4',
            category: 'boundary',
            type: 'administrative',
            importance: 0.4612931222686,
            icon: 'https://nominatim.openstreetmap.org/images/mapicons/poi_boundary_administra'\
                    'tive.p.20.png',
            address: {
              country: 'The Netherlands',
              country_code: 'nl'
            },
            extratags: {
              place: 'country',
              wikidata: 'Q29999',
              wikipedia: 'nl:Koninkrijk der Nederlanden',
              population: '16645313'
            },
            namedetails: {
              name: 'Nederland',
              int_name: 'Nederland'
            }
          }
        ].to_json
      end

      expectation.times = unlimited
    end
    client.register(expectation)
  end
end
