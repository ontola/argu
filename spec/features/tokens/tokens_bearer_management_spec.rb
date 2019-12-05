# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Token bearer management', type: :feature do
  example 'Owner adds and retracts bearer token' do
    as('staff@example.com', location: '/argu/g/111/settings')
    select_tab('Invite by link')

    wait_for(page).to have_content 'Invite links'

    resource_selector(
      'https://app.argu.localtest/argu/tokens/bearer/g/111?display=settingsTable',
      element: '.ContainerFloat',
      child: '.fa-plus'
    ).click

    wait_for(page).to have_content('New invite link')
    fill_in 'https://argu.co/ns/core#redirectUrl', with: 'https://www.example.com'
    click_button 'Create'

    wait_for(page).to have_snackbar 'Invite link created successfully'

    expect(token_row(1)).to have_content('https://www.example.com')

    within(token_row(1)) do
      wait(30).for(page).to have_css('.fa-close')
      find('td:last-child a').click
    end

    wait_for(page).to(
      have_content('This object and all related data will be permanently removed. This cannot be undone.')
    )
    click_button 'Delete'

    wait_for(page).to have_snackbar 'Invite link deleted successfully'
    expect(page).not_to have_content('https://www.example.com')
  end

  private

  def token_row(row = 1)
    resource_selector(
      'https://app.argu.localtest/argu/tokens/bearer/g/111?display=settingsTable',
      child: "tbody tr:nth-child(#{row})",
      element: '.Card'
    )
  end
end