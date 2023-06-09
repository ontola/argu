# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Redirect', type: :feature do
  let(:location) { '/argu/q/freetown_motion' }
  let(:redirect_location) { '/argu/m/freetown_motion' }

  example 'cold redirect of wrong type' do
    as :guest, location: location
    wait_for { playwright_page.url }.to include(redirect_location)
  end

  example 'cold redirects with exact match' do
    redis_cache_persisted_client.hset(
      'cache:Redirect:Exact',
      'https://redirect.argu.localtest/argu' => 'https://argu.localtest/argu'
    )
    visit 'https://redirect.argu.localtest/argu'
    wait_for { playwright_page.url }.to include('https://argu.localtest/argu')
  end
end
