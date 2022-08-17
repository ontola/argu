# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Token email management', type: :feature do
  example 'Owner adds and retracts email token' do
    as('staff@example.com', location: '/argu/g/111/settings')
    select_tab('Invite by email')

    wait_for { page }.to have_content 'Email invites'
    playwright_page.locator('h2', hasText: 'Email invites').click

    collection_float_button('New email invite').click

    wait_for { page }.to have_content('New email invite')

    fill_in field_name('https://argu.co/ns/core#emailAddresses'), with: 'user3@example.com '
    fill_in field_name('https://ns.ontola.io/core#redirectUrl'), with: 'https://www.example.com'
    click_button 'Create'

    wait_for { page }.to have_snackbar 'Email invite created successfully'

    wait_for { page }.to have_content('https://www.example.com')

    row = token_row(1)
    expect(row.locator('text=https://www.example.com').visible?).to be_truthy
    wait_for { row.locator('.fa-close').visible? }.to be_truthy
    row.locator('td:last-child a').click

    within_dialog do
      wait_for { page }.to(
        have_content('This object and all related data will be permanently removed. This cannot be undone.')
      )
      click_button 'Delete'
    end

    # @todo fix stale element error for window.logging
    # wait_for { page }.to have_snackbar 'Email invite deleted successfully'
    expect(page).not_to have_content('https://www.example.com')

    expect_email(:invite_email)

    expect(invite_email.body).to include("I invite you to join the group 'Members'.")
  end

  # @todo send invite as different actor
  # @todo send invite as with empty message
  # @todo validate email format
  # @todo redirect url

  private

  def invite_email
    @invite_email ||= mailcatcher_email(to: ['user3@example.com'], subject: 'Invitation for Argu page')
  end

  def token_row(row = 1)
    resource_selector(
      'https://argu.localtest/argu/tokens/g/111/email?display=settingsTable',
      child: "tbody tr:nth-child(#{row})",
      element: '.CID-Card'
    )
  end
end
