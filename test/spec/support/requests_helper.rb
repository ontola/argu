# frozen_string_literal: true

require 'httparty'
require 'faraday/multipart'
require 'oj'
require 'rdf'
require 'rdf/vocab'

require_relative './slice_helper_methods'

module RequestsHelper
  include SliceHelperMethods

  LD = RDF::Vocabulary.new('http://purl.org/linked-delta/')
  FORM = RDF::Vocabulary.new('https://ns.ontola.io/form#')
  ONTOLA = RDF::Vocabulary.new('https://ns.ontola.io/core#')

  attr_reader :response, :request, :headers, :body, :current_slice

  def bulk(resources, **opts)
    set_result HTTParty.post(
      'https://argu.localtest/argu/link-lib/bulk',
      headers: request_headers.merge(opts[:headers] || {}),
      body: Array(resources).to_query('resource'))
    verify_result
  end

  def change_language(language)
    cookies, csrf = authentication_values

    conn = Faraday.new(url: 'https://argu.localtest/argu/user/language') do |faraday|
      faraday.request :multipart
      faraday.adapter :net_http
    end
    response = conn.put do |req|
      req.headers.merge!(
        'Accept': 'application/empathy+json',
        'Content-Type': 'application/empathy+json',
        'Cookie' => HTTP::Cookie.cookie_value(cookies),
        'X-CSRF-Token' => csrf,
        'Website-IRI' => 'https://argu.localtest/argu'
      )
      req.body = change_language_body(language)
    end

    @cookies = HTTP::CookieJar.new.parse(response.headers['set-cookie'], 'https://argu.localtest')
  end

  def request_headers
    {
      Accept: 'application/empathy+json',
      'Accept-Language': 'en-US',
      'Cookie': @cookies && HTTP::Cookie.cookie_value(@cookies),
      'Website-IRI': 'https://argu.localtest/argu',
      'X-Forwarded-Host': 'argu.localtest',
      'X-Forwarded-Proto': 'https',
      'X-Forwarded-Ssl': 'on'
    }
  end

  private

  def change_language_body(language)
    {
      '.' => {
        'http://schema.org/language' => "https://argu.localtest/argu/enums/users/language##{language}"
      }
    }.to_emp_json.to_json
  end

  def requested_iri
    RDF::URI(request.uri.to_s)
  end

  def set_result(value)
    @request = value.request
    @response = value.response
    @headers = value.headers
    @body = value.body
    @current_slice = value.body ? Oj.load(value.body) : {}
  end

  def expect_value(subject, predicate, object)
    expect_slice_attribute(
      current_slice,
      normalize_iri(subject),
      normalize_iri(predicate),
      object,
      current_tenant
    )
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
    # expect(headers['server']).to start_with("Apex/")
  end
end
