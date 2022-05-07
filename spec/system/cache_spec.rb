# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cache', type: :system do
  let(:tenantized_ontology) { 'https://argu.localtest/argu/ns/core' }
  let(:motion_form) { 'https://argu.localtest/argu/forms/motions' }
  let(:motion_new) { 'https://argu.localtest/argu/freetown/m/new' }
  let(:pro_argument_class) { 'https://argu.co/ns/core#ProArgument' }
  let(:subject) {}

  context 'without language' do
    it 'fetches the ontology' do
      bulk tenantized_ontology

      expect(current_slice).to include_value(tenantized_ontology, RDF::RDFV[:type], RequestsHelper::ONTOLA[:Ontology])
    end

    it 'Serves all languages without language header' do
      bulk tenantized_ontology

      expect(current_slice).to include_value(pro_argument_class, RDF::RDFS[:label], RDF::Literal('Voordeel', language: 'nl'))
      expect(current_slice).to include_value(pro_argument_class, RDF::RDFS[:label], RDF::Literal('Pro', language: 'en'))
    end

    it 'Serves all languages with language header' do
      bulk tenantized_ontology,
           headers: {
             'Accept-Language' => 'nl'
           }

      expect(current_slice).to include_value(pro_argument_class, RDF::RDFS[:label], RDF::Literal('Voordeel', language: 'nl'))
      expect(current_slice).to include_value(pro_argument_class, RDF::RDFS[:label], RDF::Literal('Pro', language: 'en'))
    end

    it 'Serves motion form without language header' do
      bulk motion_form

      expect(current_slice).to include_value(motion_form, RDF::RDFV[:type], RequestsHelper::FORM[:Form])
      expect(current_slice).to include_some_value(RDF::Vocab::SCHEMA.name, 'Title')
      expect(current_slice).not_to include_some_value(RDF::Vocab::SCHEMA.name, 'Titel')
    end

    it 'Serves motion new action without language header' do
      bulk motion_new

      expect(current_slice).to include_value(motion_new, RDF::RDFV[:type], RequestsHelper::ONTOLA['Create::Motion'])
      expect(current_slice).to include_value(motion_new, RDF::Vocab::SCHEMA.name, RDF::Literal('New idea'))
    end

    it 'Serves motion new action in page language with language header' do
      bulk motion_new,
           headers: {
             'Accept-Language' => 'nl'
           }

      expect(current_slice).to include_value(motion_new, RDF::RDFV[:type], RequestsHelper::ONTOLA['Create::Motion'])
      expect(current_slice).to include_value(motion_new, RDF::Vocab::SCHEMA.name, RDF::Literal('New idea'))
    end
  end

  context 'with language' do
    it 'Serves motion new action in user language' do
      change_language('nl')

      bulk motion_new

      expect(current_slice).to include_value(motion_new, RDF::RDFV[:type], RequestsHelper::ONTOLA['Create::Motion'])
      expect(current_slice).to include_value(motion_new, RDF::Vocab::SCHEMA.name, RDF::Literal('Nieuw idee'))
    end

    it 'Serves motion form in user language' do
      change_language('nl')

      bulk motion_form

      expect(current_slice).to include_value(motion_form, RDF::RDFV[:type], RequestsHelper::FORM[:Form])
      expect(current_slice).to include_some_value(RDF::Vocab::SCHEMA.name, 'Titel')
      expect(current_slice).not_to include_some_value(RDF::Vocab::SCHEMA.name, 'Title')
    end
  end
end
