# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Token bearer management', type: :feature do
  example 'Owner adds and retracts bearer token' do
    as('staff@example.com', location: '/argu/g/111/settings')
    select_tab('Invite by link')

    find('h2', text: 'Invite links').click
    wait_for { page }.to have_content 'Invite links'

    resource_selector(
      'https://argu.localtest/argu/tokens/g/111/bearer?display=settingsTable',
      element: '.ContainerFloat',
      child: '.fa-plus'
    ).click

    wait_for { page }.to have_content('New invite link')
    fill_in field_name('https://ns.ontola.io/core#redirectUrl'), with: 'https://www.example.com'
    click_button 'Create'

    wait_for { page }.to have_snackbar 'Invite link created successfully'

    wait_for { page }.to have_content('https://www.example.com')
    expect(token_row(1)).to have_content('https://www.example.com')

    within(token_row(1)) do
      wait(30).for(page).to have_css('.fa-close')
      find('td:last-child a').click
    end

    within_dialog do
      wait_for { page }.to(
        have_content('This object and all related data will be permanently removed. This cannot be undone.')
      )
      click_button 'Delete'
    end
    # @todo fix stale element error for window.logging
    # wait_for { page }.to have_snackbar 'Invite link deleted successfully'
    expect(page).not_to have_content('https://www.example.com')
  end

  private

  def token_row(row = 1)
    resource_selector(
      'https://argu.localtest/argu/tokens/g/111/bearer?display=settingsTable',
      child: "tbody tr:nth-child(#{row})",
      element: '.CID-Card'
    )
  end
end
