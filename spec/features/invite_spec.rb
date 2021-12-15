# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Invites', type: :feature do
  example 'Administrator invites user for existing group' do
    as 'staff@example.com', location: '/argu/m/freetown_motion'
    go_to_menu_item('Invite', menu: :share)
    wait_for { page }.to have_content 'Invite people'
    fill_in field_name('https://argu.co/ns/core#emailAddresses'), with: 'invitee1@example.com invitee2@example.com '
    fill_in field_name('https://argu.co/ns/core#message'), with: 'Example body'
    fill_in_select field_name('https://argu.co/ns/core#groupId'), with: 'custom'
    fill_in field_name('https://ns.ontola.io/core#redirectUrl'), with: 'https://www.example.com'
    click_button 'Save'
    wait_for { page }.to have_snackbar 'Email invite created successfully'
    expect(token_row).to have_content('invitee2@example.com')
    expect(token_row).to have_content('https://www.example.com')
    expect(token_row).to have_content('invitee1@example.com')
    expect(token_row).to have_content('https://www.example.com')

    expect_email :invite_email_1
    expect_email :invite_email_2
  end

  example 'Administrator invites user for new group' do
    as 'staff@example.com', location: '/argu/m/freetown_motion'
    go_to_menu_item('Invite', menu: :share)
    wait_for { page }.to have_content 'Invite people'
    fill_in field_name('https://argu.co/ns/core#emailAddresses'), with: 'invitee1@example.com invitee2@example.com '
    fill_in field_name('https://argu.co/ns/core#message'), with: 'Example body'
    fill_in field_name('https://ns.ontola.io/core#redirectUrl'), with: 'https://www.example.com'
    within resource_selector('https://argu.co/ns/core#groupId') do
      wait_for { page }.to have_css('.fa-plus')
      find('.fa-plus').click
    end
    wait_for(page).to have_content('Name singular')
    within_dialog do
      fill_in field_name('http://schema.org/name'), with: 'people'
      fill_in field_name('https://argu.co/ns/core#nameSingular'), with: 'person'
      click_button 'Save'
    end
    wait_for { page }.to have_snackbar 'Group created successfully'
    wait_for(page).to have_content('To which group do you want to add these people?')
    wait_until_loaded
    fill_in_select field_name('https://argu.co/ns/core#groupId'), with: 'people'
    click_button 'Save'
    wait_for { page }.to have_snackbar 'Email invite created successfully'
    expect(token_row(5)).to have_content('invitee2@example.com')
    expect(token_row(5)).to have_content('https://www.example.com')
    expect(token_row(5)).to have_content('invitee1@example.com')
    expect(token_row(5)).to have_content('https://www.example.com')

    expect_email :invite_email_1
    expect_email :invite_email_2
  end

  private

  def invite_email_1
    @invite_email_1 ||= mailcatcher_email(
      to: ['invitee1@example.com'],
      subject: 'Uitnodiging voor Argu page'
    )
  end

  def invite_email_2
    @invite_email_2 ||= mailcatcher_email(
      to: ['invitee2@example.com'],
      subject: 'Uitnodiging voor Argu page'
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
