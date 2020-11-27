# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Not found', type: :feature do
  example 'request non-cached non authorized resource' do
    as(:guest, location: '/argu/q/55')
    wait_for { page }.to have_content('This item is hidden')
    wait_for { page }.to have_button('Log in')
    wait_for { page }.not_to have_content('Fg question title 8end')
  end

  example 'request cached non authorized resource' do
    as('staff@example.com', location: '/argu/q/55')
    wait_for { page }.to have_content('Fg question title 8end')
    wait_for { page }.not_to have_content('This item is hidden')
    wait_for { page }.not_to have_button('Log in')
    logout
    wait_for { page }.to have_content('This item is hidden')
    wait_for { page }.to have_button('Log in')
    wait_for { page }.not_to have_content('Fg question title 8end')
  end
end
