# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Direct messages', type: :feature do
  let(:new_email) { 'new_email@example.com'}

  example 'Staff sends a direct message' do
    as 'staff@example.com', location: '/argu/m/freetown_motion'
    go_to_menu_item('Contact poster')
    wait_for { page }.to have_content 'Send an e-mail to user_name_34'
    fill_in field_name('http://schema.org/name'), with: 'Example subject'
    fill_in field_name('http://schema.org/text'), with: 'Example body'
    click_button 'Send'
    wait_for { page }.to have_snackbar 'The mail will be sent'
    expect_email :direct_message_email
    expect(direct_message_email.instance_variable_get(:@mail).reply_to.first).to eq('staff@example.com')
    expect(direct_message_email.body).to(
      have_content('argu_owner has sent you a message in response to Freetown_motion-title.')
    )
  end

  example 'Staff sends a direct message with other email' do
    as 'staff@example.com', location: '/argu/m/freetown_motion'
    go_to_menu_item('Contact poster')
    wait_for { page }.to have_content('Send an e-mail to user_name_34')
    within resource_selector('http://schema.org/email') do
      wait_for { page }.to have_css('.fa-plus')
      find('.fa-plus').click
    end
    wait_until_loaded
    within('.MuiDialog-paper') do
      fill_in field_name('http://schema.org/email'), with: new_email
      click_button('Add')
    end
    expect_email(:add_address_email)
    visit add_address_email.links.last
    visit 'https://argu.localtest/argu/m/freetown_motion/dm/new'
    fill_in_select(field_name('http://schema.org/email'), with: new_email)
    fill_in field_name('http://schema.org/name'), with: 'Example subject'
    fill_in field_name('http://schema.org/text'), with: 'Example body'
    fill_in_select(field_name('http://schema.org/creator'), with: 'Argu page')
    click_button 'Send'
    wait_for { page }.to have_snackbar 'The mail will be sent'
    expect_email :direct_message_email
    expect(direct_message_email.instance_variable_get(:@mail).reply_to.first).to eq(new_email)
    expect(direct_message_email.body).to(
      have_content('Argu page has sent you a message in response to Freetown_motion-title.')
    )
  end

  private

  def add_address_email
    @add_address_email ||= mailcatcher_email(to: [new_email], subject: 'Add your e-mail address')
  end

  def direct_message_email
    @direct_message_email ||= mailcatcher_email(
      to: ['user32@example.com'],
      subject: 'Example subject'
    )
  end
end
