# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Redirect', type: :feature do
  let(:location) { '/argu/q/38' }
  let(:redirect_location) { '/argu/m/38' }

  example 'cold redirect of wrong type' do
    as :guest, location: location
    wait_for(page.current_url).to include(redirect_location)
  end

  example 'cold redirect on app.' do
    docker_exec('redis', [
      'redis-cli',
      '-u',
      ENV['REDIS_URL'],
      'SET',
      'backend.redirects.https://app.argu.localtest/argu',
      'https://argu.localtest/argu'
    ])
    visit 'https://app.argu.localtest/argu'
    wait_for(page.current_url).to include('https://argu.localtest/argu')
  end
end
