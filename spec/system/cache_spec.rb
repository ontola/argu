# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cache', type: :system do
  let(:core_ontology) { 'https://argu.co/ns/core' }
  let(:tenantized_ontology) { 'https://argu.localtest/argu/ns/core' }
  let(:motion) { 'https://argu.localtest/argu/m/38' }
  let(:subject) {}

  context 'as guest' do
    it 'fetches the ontology' do
      bulk core_ontology

      expect_triple(tenantized_ontology, RDF::RDFV[:type], RequestsHelper::ONTOLA[:Vocabulary], nil)
    end

    it 'Serves all languages without language header' do
      bulk core_ontology,
          headers: {
            'Accept-Language' => 'nl'
          }

      expect_triple('https://argu.co/ns/core#ProArgument', RDF::RDFS[:label], RDF::Literal('Voordeel', language: 'nl'), nil)
      expect_triple('https://argu.co/ns/core#ProArgument', RDF::RDFS[:label], RDF::Literal('Pro', language: 'en'), nil)
    end

    it 'Serves all languages with language header' do
      bulk core_ontology

      expect_triple('https://argu.co/ns/core#ProArgument', RDF::RDFS[:label], RDF::Literal('Voordeel', language: 'nl'), nil)
      expect_triple('https://argu.co/ns/core#ProArgument', RDF::RDFS[:label], RDF::Literal('Pro', language: 'en'), nil)
    end

    it 'Serves motion' do
      bulk motion

      expect_triple('https://argu.co/ns/core#ProArgument', RDF::RDFS[:label], RDF::Literal('Voordeel', language: 'nl'), nil)
      expect_triple('https://argu.co/ns/core#ProArgument', RDF::RDFS[:label], RDF::Literal('Pro', language: 'en'), nil)
    end
  end
end
