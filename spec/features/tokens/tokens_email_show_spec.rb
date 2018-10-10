require 'spec_helper'

RSpec.describe 'Token email show', type: :feature do
  context 'valid token' do
    let(:token) { '/tokens/valid_email_token' }

    example 'new user visits token' do
      as(:guest, location: token)

      # @todo wait_for(page).to have_content("You have joined the group 'Members'")
      wait_for(page).to have_content('Holland')
      verify_logged_in
    end

    example 'other user visits token' do
      as('user1@example.com')
      visit "https://argu.localtest#{token}"

      wait_for(page).to have_content('The invitation you are following is meant for invitee@example.com')
      expect(page).to have_content('add invitee@example.com')
      # @TODO continue flow
      # click_button 'Log out'
      #
      # expect(page).to have_content('Please login to accept this invitation')
      # click_link 'Sign up with email'
      #
      # expect(page).not_to have_content('REGISTER OR LOG IN')
      # within('#new_user') do
      #   fill_in 'user_email', with: 'invitee@example.com'
      #   fill_in 'user_password', with: 'password'
      #   fill_in 'user_password_confirmation', with: 'password'
      #   click_button 'Sign up'
      # end
      #
      # expect(page).to have_content('WELCOME!')
      # click_button 'Next'
      # expect(page).to have_content('FINISH YOUR ACCOUNT')
      # click_button 'Skip'
      #
      # expect_joined
    end

    example 'user with second email address visits token' do
      as('user1@example.com')
      visit "https://argu.localtest#{token}"

      wait_for(page).to have_content('The invitation you are following is meant for invitee@example.com')
      # @TODO continue flow
      # click_button 'Add invitee@example.com'
      #
      # expect_joined
    end
  end

  context 'user token' do
    let(:token) { '/tokens/user_email_token' }

    example 'logged out user visits token' do
      as(:guest, location: token)

      # @todo render snackbar on a 401
      # wait_for(page).to have_content('Please login to accept this invitation')
      wait_for(page).to have_content 'inloggen of registreren'

      fill_in_login_form

      expect_joined
    end

    example 'user visits token' do
      as('user1@example.com')
      visit "https://argu.localtest#{token}"

      expect_joined
    end

    example 'other user visits token' do
      as('member@example.com')
      visit "https://argu.localtest#{token}"

      wait(30).for(page).to have_content('The invitation you are following is meant for user1@example.com')
      expect(page).not_to have_content('add user1@example.com')

      # @TODO continue flow
      # click_button 'Log out'
      #
      # # @todo render snackbar on a 401
      # # wait_for(page).to have_content('Please login to accept this invitation')
      # wait_for(page).to have_content 'inloggen of registreren'
      #
      # fill_in_login_form
      #
      # expect_joined
    end
  end

  context 'member token' do
    let(:token) { '/tokens/member_email_token' }

    example 'logged out member visits token' do
      as(:guest, location: token)

      # @todo render snackbar on a 401
      # wait_for(page).to have_content('Please login to accept this invitation')
      wait_for(page).to have_content 'inloggen of registreren'

      fill_in_login_form 'member@example.com'

      expect_member_already
    end

    example 'member visits token' do
      as('member@example.com')
      visit "https://argu.localtest#{token}"

      expect_member_already
    end
  end

  private

  def expect_joined
    wait_for(page).to have_content("You have joined the group 'Members'")
    wait_for(page).to have_content('Holland')
    expect(page).not_to have_content('Add to my forums')
  end

  def expect_member_already
    wait_for(page).to have_content('You are already member of this group')
    wait_for(page).to have_content('Holland')
    expect(page).not_to have_content('Add to my forums')
  end
end
