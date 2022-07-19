# frozen_string_literal: true

require 'empathy/emp_json/helpers/slices'
require 'empathy/emp_json/helpers/primitives'

module SliceHelperMethods
  include Empathy::EmpJson::Helpers::Slices
  include Empathy::EmpJson::Helpers::Primitives

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
end
