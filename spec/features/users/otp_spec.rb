# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Otp', type: :feature do
  let(:form_group) { 'Authentication' }

  context 'user without otp' do
    before { as('user1@example.com') }

    example 'adds 2fa' do
      visit_settings
      wait_for { page }.to have_button('Two factor authentication')
      expect(page).not_to have_button('Disable two factor authentication')
      click_button 'Two factor authentication'
      wait_for { page }.to have_content('Install a authentication-application and scan this QR code.')
      wait_for(page).not_to have_content('Disable two factor authentication')
      otp = var_from_rails_console('EmailAddress.find_by(email: \'user1@example.com\').user.otp_secret.otp_code')

      fill_in field_name('https://argu.co/ns/core#otp'), with: otp, fill_options: {clear: :backspace}
      click_button 'Continue'
      wait_until_loaded
      visit_settings

      wait_for { page }.to have_button('Disable two factor authentication')
      expect(page).not_to have_button('Two factor authentication')
    end

    example 'fails to add 2fa with wrong code' do
      visit_settings
      wait_for { page }.to have_button('Two factor authentication')
      expect(page).not_to have_button('Disable two factor authentication')
      click_button 'Two factor authentication'
      wait_for(page).to have_content('Install a authentication-application and scan this QR code.')
      fill_in field_name('https://argu.co/ns/core#otp'), with: '123456', fill_options: {clear: :backspace}
      click_button 'Continue'
      wait_for { page }.to have_content 'The authentication code is incorrect.'
    end
  end

  context 'user with otp' do
    before { as(:guest) }

    example 'removes 2fa' do
      login '2fa@example.com', 'password', two_fa: true

      visit_settings
      wait_for { page }.to have_button('Disable two factor authentication')
      expect(page).not_to have_button('Two factor authentication')
      click_button 'Disable two factor authentication'
      wait_for(page).not_to have_content('Install a authentication-application and scan this QR code.')
      wait_for(page).to have_content('Disable two factor authentication')

      click_button 'Confirm'
      wait_until_loaded
      visit_settings

      wait_for { page }.to have_button('Two factor authentication')
      expect(page).not_to have_button('Disable two factor authentication')
    end
  end

  private

  def visit_settings
    go_to_user_page('Settings')

    wait_for { page }.to have_content form_group
    expand_form_group form_group
  end
end
