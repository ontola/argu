# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User request confirmation', type: :feature do
  context 'unconfirmed@example.com' do
    let(:email) { 'unconfirmed@example.com' }

    example 'guest requests confirmation of unconfirmed email' do
      as(:guest, location: '/argu/u/confirmation/new')

      request_confirmation_link

      wait_for { page }.to(
        have_snackbar("You'll receive a mail containing instructions to confirm your account within a few minutes.")
      )
      expect_email(:confirmation_email)

      visit confirmation_email.links.last

      wait_for { page }.to have_current_path('/argu')
      verify_logged_in('unconfirmed@example.com')

      expect_confirmed
    end

    example 'guest requests confirmation of unconfirmed email and accepts as other user' do
      as(:guest, location: '/argu/u/confirmation/new')

      request_confirmation_link

      wait_for { page }.to(
        have_snackbar("You'll receive a mail containing instructions to confirm your account within a few minutes.")
      )
      expect_email(:confirmation_email)

      login 'user1@example.com', modal: false

      visit confirmation_email.links.last

      wait_for { page }.to have_current_path('/argu')

      verify_logged_in('unconfirmed@example.com')

      expect_confirmed
    end

    example 'unconfirmed user requests confirmation' do
      as(email, location: '/argu/u/confirmation/new')

      request_confirmation_link

      wait_for { page }.to(
        have_snackbar("You'll receive a mail containing instructions to confirm your account within a few minutes.")
      )
      logout
      verify_not_logged_in

      expect_email(:confirmation_email)

      visit confirmation_email.links.last

      wait_for { page }.to have_current_path('/argu')

      verify_logged_in('unconfirmed@example.com')

      expect_confirmed
    end

    example 'user requests confirmation of wrong email' do
      as('user1@example.com', location: '/argu/u/confirmation/new')

      request_confirmation_link

      wait_for { page }.to(have_snackbar('unconfirmed@example.com does not exist or belongs to a different user.'))
    end
  end

  context 'user1@example.com' do
    let(:email) { 'user1@example.com' }

    example 'guest requests confirmation of confirmed email' do
      as(:guest, location: '/argu/u/confirmation/new')

      request_confirmation_link

      wait_for { page }.to(
        have_snackbar("You'll receive a mail containing instructions to confirm your account within a few minutes.")
      )
      expect_email(:confirmation_email)

      visit confirmation_email.links.last

      wait_for { page }.to have_snackbar 'Email was already confirmed, try to log in.'

      wait_until_loaded
      verify_not_logged_in
    end

    example 'user requests confirmation' do
      as(email, location: '/argu/u/confirmation/new')

      request_confirmation_link

      wait_for { page }.to(
        have_snackbar("You'll receive a mail containing instructions to confirm your account within a few minutes.")
      )

      logout
      verify_not_logged_in

      expect_email(:confirmation_email)

      visit confirmation_email.links.last

      wait_for { page }.to have_snackbar 'Email was already confirmed, try to log in.'

      wait_until_loaded
      verify_not_logged_in
    end
  end

  example 'guest visits non-existing token' do
    as(:guest, location: '/argu/u/confirmation?confirmation_token=wrong_token')
    wait_for { page }.to have_content 'This item is not found'
  end

  private

  def confirmation_email
    @confirmation_email ||= mailcatcher_email(to: [email], subject: 'Confirm your e-mail address')
  end

  def expect_confirmed
    # @todo snackbars are shown, but the page is instantly reloaded.
    # wait_for { page }.to(have_snackbar('Your account has been confirmed.'))

    go_to_user_page('Settings')

    wait_for { page }.to have_content 'Email addresses'
    expand_form_group 'Email addresses'

    wait_for { page }.to have_content email
    wait_for { page }.not_to have_content 'Send again'
  end

  def request_confirmation_link
    wait_for { page }.to have_content('Send confirmation link again')
    fill_in placeholder: 'email@example.com', with: email
    click_button 'Send'
  end
end
