# frozen_string_literal: true

require 'active_support/time_with_zone'
require 'linked_rails/vocab'
require 'linked_rails/emp_json/constants'
require 'linked_rails/emp_json/primitives'
require 'linked_rails/emp_json/fields'

class NS < LinkedRails::Vocab; end

module SliceHelperMethods
  include LinkedRails::EmpJSON::Primitives
  include LinkedRails::EmpJSON::Fields


  attr_accessor :symbolize

  def expect_slice_subjects(slice, *subjects, partial_match: false)
    iris = subjects.map { |subject| (subject.try(:iri) || subject).to_s }
    iris.each { |iri| assert_includes(slice.keys, iri) }

    return if partial_match

    assert_equal(
      subjects.count,
      slice.keys.count,
      "Found additional subjects: #{slice.keys - iris}"
    )
  end

  def expect_slice_attribute(slice, subject, predicate, object, website_iri = nil)
    values = values_from_slice(slice, subject, predicate, website_iri)

    if object.nil?
      assert_nil(values)
    else
      expected = normalise_slice_expectations(object)
      record = record_from_slice(slice, subject, website_iri)
      message = "Expected #{subject} to have field #{predicate} with value #{expected}: #{record}"
      expect(values).to eq(expected), message
    end
  end

  def normalise_slice_expectations(values)
    normalise_slice_values(
      values.is_a?(Array) ? values.map { |v| primitive_to_value(v) } : primitive_to_value(values)
    )
  end

  def normalise_slice_values(values)
    values.is_a?(Array) ? values.map(&:with_indifferent_access) : values&.with_indifferent_access
  end

  def all_values_from_slice(slice, field, website_iri = nil)
    slice
      .values
      .flat_map { |record| field_from_record(record, field) }
      .map { |values| normalise_slice_values(values) }
      .compact
  end

  # Returns a normalised fields array for a record from a slice.
  def values_from_slice(slice, id, field, website_iri = nil)
    values = field_from_slice(slice, id, field, website_iri)

    normalise_slice_values(values)
  end

  # Returns the fields for a record from a slice.
  def field_from_slice(slice, id, field, website_iri = nil)
    record = record_from_slice(slice, id, website_iri)
    return unless record.present?

    field_from_record(record, field)
  end

  # Returns a record from a slice.
  def record_from_slice(slice, id, website_iri = nil)
    slice[retrieve_id(id, website_iri)]
  end

  def field_from_record(record, field)
    field = URI(field.to_s)
    symbolized = (field.fragment || field.path.split('/').last).camelize(:lower)
    (record[field] || record[symbolized])&.compact
  end

  def retrieve_id(id, website_iri = nil)
    absolutized_id(id.try(:iri) || id, website_iri)
  end

  def absolutized_id(id, website_iri = nil)
    return id.to_s.delete_prefix(website_iri) if website_iri.present?

    id.to_s
  end

  def expand(slice, website_iri = current_tenant)
    return slice unless website_iri.present?

    slice
      .map { |k, v| [k.start_with?('/') ? website_iri + k : k, v] }
      .to_h
  end

  def field_to_symbol(uri)
    (uri.fragment || uri.path.split('/').last).camelize(:lower)
  end

  def remove_website_iri_prefix(id, website_iri)

  end
end
