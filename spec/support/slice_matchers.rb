# frozen_string_literal: true

module SliceMatchers
  RSpec::Matchers.define :include_value do |id, field, expected, website_iri|
    include SliceHelperMethods

    match do |actual|
      website_iri ||= current_tenant
      slice = actual
      @expected = normalise_slice_expectations(expected)
      @actual = values_from_slice(slice, id, field, website_iri)

      if @actual.is_a?(Array)
        @actual.include?(@expected)
      else
        @actual == @expected
      end
    end

    diffable
  end

  # Matches when the slice contains a [field] with a value [expected].
  # Does not check what record the field is on.
  RSpec::Matchers.define :include_some_value do |field, expected, website_iri|
    include SliceHelperMethods

    match do |actual|
      website_iri ||= current_tenant
      slice = actual
      @expected = normalise_slice_expectations(expected)
      @actual = all_values_from_slice(slice, field, website_iri)

      if @actual.is_a?(Array)
        @actual.include?(@expected)
      else
        @actual == @expected
      end
    end

    diffable
  end
end
