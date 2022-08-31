# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Invites', type: :feature do
  example 'Administrator invites user for existing group' do
    as 'staff@example.com', location: '/argu/m/freetown_motion'
    go_to_menu_item('Invite', menu: :share)
    wait_for { page }.to have_content 'Invite people'
    playwright_page.locator('button', hasText: 'Via email').click
    fill_in_email_input field_name('https://argu.co/ns/core#emailAddresses'),
                        with: ['invitee1@example.com', 'invitee2@example.com']
    fill_in field_name('https://argu.co/ns/core#message'), with: 'Example body'
    fill_in_select field_name('https://argu.co/ns/core#group'), with: 'custom'
    expand_form_group('Advanced')
    fill_in field_name('https://ns.ontola.io/core#redirectUrl'), with: 'https://www.example.com'
    click_button 'Create invite'
    wait_for { page }.to have_snackbar 'Email invite created successfully'

    token_row.locator('text=invitee2@example.com')
    token_row.locator('text=https://www.example.com')
    token_row.locator('text=invitee1@example.com')
    token_row.locator('text=https://www.example.com')

    expect_email :invite_email_1
    expect_email :invite_email_2
  end

  private

  def invite_email_1
    @invite_email_1 ||= mailcatcher_email(
      to: ['invitee1@example.com'],
      subject: 'Invitation for Argu page'
    )
  end

  def invite_email_2
    @invite_email_2 ||= mailcatcher_email(
      to: ['invitee2@example.com'],
      subject: 'Invitation for Argu page'
    )
  end

  def token_row(group_id = 4)
    resource_selector(
      "https://argu.localtest/argu/tokens/g/#{group_id}/email?display=settingsTable",
      child: "tbody",
      element: '.CID-Card'
    )
  end
end
