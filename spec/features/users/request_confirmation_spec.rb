# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User request confirmation', type: :feature do
  let(:confirmation_email) { mailcatcher_email(to: [email], subject: 'Confirm your e-mail address') }

  context 'unconfirmed@example.com' do
    let(:email) { 'unconfirmed@example.com' }

    example 'guest requests confirmation of unconfirmed email' do
      as(:guest, location: '/users/confirmation/new')

      request_confirmation_link

      wait_for(page).to(
        have_content("You'll receive a mail containing instructions to confirm your account within a few minutes")
      )
      expect_email(:confirmation_email)

      visit confirmation_email.links.last

      expect_confirmed
    end

    example 'guest requests confirmation of unconfirmed email and accepts as other user' do
      as(:guest, location: '/users/confirmation/new')

      request_confirmation_link

      wait_for(page).to(
        have_content("You'll receive a mail containing instructions to confirm your account within a few minutes")
      )
      expect_email(:confirmation_email)

      login 'user1@example.com'

      visit confirmation_email.links.last

      expect_confirmed

      # @TODO expect logged in as user1@example.com
    end

    example 'unconfirmed user requests confirmation' do
      as(email, location: '/users/confirmation/new')

      request_confirmation_link

      wait_for(page).to(
        have_content("You'll receive a mail containing instructions to confirm your account within a few minutes")
      )
      expect_email(:confirmation_email)

      visit confirmation_email.links.last

      expect_confirmed
    end

    example 'user requests confirmation of wrong email' do
      as('user1@example.com', location: '/users/confirmation/new')

      request_confirmation_link

      wait_for(page).to(have_content('unconfirmed@example.com does not exist or belongs to a different user.'))
    end
  end

  context 'user1@example.com' do
    let(:email) { 'user1@example.com' }

    example 'guest requests confirmation of confirmed email' do
      as(:guest, location: '/users/confirmation/new')

      request_confirmation_link

      wait_for(page).to(
        have_content("You'll receive a mail containing instructions to confirm your account within a few minutes")
      )
      expect_email(:confirmation_email)

      visit confirmation_email.links.last

      wait_for(page).to have_content 'Het item kan niet worden verwerkt'
    end

    example 'user requests confirmation' do
      as(email, location: '/users/confirmation/new')

      request_confirmation_link

      wait_for(page).to(
        have_content("You'll receive a mail containing instructions to confirm your account within a few minutes")
      )
      expect_email(:confirmation_email)

      visit confirmation_email.links.last

      wait_for(page).to have_content 'Het item kan niet worden verwerkt'
    end
  end

  example 'guest visits non-existing token' do
    as(:guest, location: '/users/confirmation?confirmation_token=wrong_token')
    wait_for(page).to have_content 'Het item kan niet worden verwerkt'
  end

  private

  def expect_confirmed
    wait_for(page).to(
      have_content('Your account has been confirmed.')
    )
  end

  def request_confirmation_link
    wait_for(page).to have_content('Send confirmation link again')
    fill_in placeholder: 'email@example.com', with: email
    click_button 'Save'
  end
end
