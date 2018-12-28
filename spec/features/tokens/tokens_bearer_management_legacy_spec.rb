# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Token bearer management legacy', type: :feature do
  before do
    use_legacy_frontend
  end

  scenario 'Owner adds and retracts bearer token' do
    as('staff@example.com', location: '/argu/g/111/settings?tab=invite')

    wait_for(page).to have_content('Invite links')
    expect(page).not_to have_css('.bearer-token-management .is-loading')
    wait_for(page).to have_css '.bearer-token-management table tbody tr', count: 1

    click_button('Generate link')

    wait_for(page).to have_css '.bearer-token-management table tbody tr', count: 2
  end
end
