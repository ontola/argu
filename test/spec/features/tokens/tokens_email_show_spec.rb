# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Token email show', type: :feature do
  context 'valid token' do
    let(:token) { '/argu/tokens/valid_email_token' }

    example 'new user visits token' do
      as(:guest, location: token)

      wait_for { page }.to have_content("invitee@example.com is invited for the group 'Members'")

      accept_token
    end

    example 'other user visits token' do
      as('user1@example.com')
      visit "https://argu.localtest#{token}"

      wait_for { page }.to have_content('The invitation you are following is meant for invitee@example.com')
      expect(page).to have_content('add invitee@example.com')
      Capybara.current_session.driver.with_playwright_page do |page|
        page.expect_navigation do
          click_button 'Create new account'
        end
      end

      fill_in_registration_form 'invitee@example.com'

      cancel_setup
      accept_token
    end

    example 'user with second email address visits token' do
      as('user1@example.com')
      visit "https://argu.localtest#{token}"

      wait_for { page }.to have_content('The invitation you are following is meant for invitee@example.com')
      click_button 'Add invitee@example.com'

      accept_token
    end
  end

  context 'user token' do
    let(:token) { '/argu/tokens/user_email_token' }

    example 'logged out user visits token' do
      as(:guest, location: token)

      wait_for { page }.to have_content('An account for this email address already exists.')
      click_link 'Log in'

      fill_in_login_form

      wait_for { page }.to have_content("You have been invited for the group 'Members'")

      accept_token
    end

    example 'user visits token' do
      as('user1@example.com')
      visit "https://argu.localtest#{token}"

      wait_for { page }.to have_content("You have been invited for the group 'Members'")
      accept_token
    end

    example 'other user visits token' do
      as('member@example.com')
      visit "https://argu.localtest#{token}"

      wait_for { page }.to have_content('The invitation you are following is meant for user1@example.com')
      expect(page).not_to have_content('add user1@example.com')

      Capybara.current_session.driver.with_playwright_page do |page|
        page.expect_navigation do
          click_button 'Switch account'
        end
      end

      fill_in_login_form modal: false

      wait_for { page }.to have_content("You have been invited for the group 'Members'")

      accept_token
    end
  end

  # used tokens

  context 'member token' do
    let(:token) { '/argu/tokens/member_email_token' }

    example 'logged out member visits token' do
      as(:guest, location: token)

      wait_for { page }.to have_content('An account for this email address already exists.')
      click_link 'Log in'

      fill_in_login_form 'member@example.com'

      accept_token result: :already_member
    end

    example 'member visits token' do
      as('member@example.com')
      visit "https://argu.localtest#{token}"

      accept_token result: :already_member
    end
  end
end
