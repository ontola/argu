# frozen_string_literal: true

require 'httparty'
require 'oj'
require 'rdf'

module RequestsHelper
  LL = RDF::Vocabulary.new('http://purl.org/link-lib/')
  ONTOLA = RDF::Vocabulary.new('https://ns.ontola.io/core#')

  attr_reader :response, :request, :headers, :body

  def get(path, **opts)
    set_result HTTParty.get(
      "https://argu.localtest#{path}",
      headers: request_headers.merge(opts[:headers] || {}))
  end

  def bulk(resources, **opts)
    set_result HTTParty.post(
      "http://apex_rs.svc.cluster.local:3030/link-lib/bulk",
      headers: request_headers.merge(opts[:headers] || {}),
      body: Array(resources).to_query('resource'))
    verify_result
  end

  def request_headers
    {
      Accept: 'application/hex+x-ndjson',
      'Accept-Language': 'en-US',
      'Website-IRI': 'https://argu.localtest/argu'
    }
  end

  private

  def requested_iri
    RDF::URI(request.uri.to_s)
  end

  def set_result(value)
    @request = value.request
    @response = value.response
    @headers = value.headers
    @body = value.body
  end

  def expect_triple(subject, predicate, object, graph = LL[:supplant])
    statement = RDF::Statement(normalize_iri(subject), normalize_iri(predicate), object, graph_name: graph)
    expect(body).to include(to_hndjson(statement))
  end

  def to_hndjson(st)
    o = st.object
    datatype = if o.is_a?(RDF::URI)
                 "http://www.w3.org/1999/02/22-rdf-syntax-ns#namedNode"
               elsif o.is_a?(RDF::Node)
                 "http://www.w3.org/1999/02/22-rdf-syntax-ns#blankNode"
               else
                 o.datatype
               end
    language = o.is_a?(RDF::Literal) ? o.language : ""

    Oj.dump([
      st.subject.to_s,
      st.predicate.to_s,
      o.value.to_s,
      datatype.to_s,
      language.to_s,
      st.graph_name.to_s
    ])
  end

  def normalize_iri(value)
    return RDF::URI(value) if value.is_a?(String)

    value
  end

  def verify_result
    expect(headers['server']).to start_with("Apex/")
  end
end
