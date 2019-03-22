# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Redirect', type: :feature do
  let(:location) { '/argu/q/38' }
  let(:redirect_location) { '/argu/m/38' }

  example 'cold redirect of wrong type' do
    as :guest, location: location
    wait_for(page.current_url).to include(redirect_location)
  end
end
