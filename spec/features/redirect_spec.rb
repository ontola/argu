# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Redirect', type: :feature do
  let(:location) { '/argu/q/freetown_motion' }
  let(:redirect_location) { '/argu/m/freetown_motion' }

  example 'cold redirect of wrong type' do
    as :guest, location: location
    wait_for { page.current_url }.to include(redirect_location)
  end

  example 'cold redirect on app.' do
    redis_cache_persisted_client.set(
      'cache:redirect:app.argu.localtest/argu',
      'https://argu.localtest/argu'
    )
    visit 'https://app.argu.localtest/argu'
    wait_for { page.current_url }.to include('https://argu.localtest/argu')
  end
end
