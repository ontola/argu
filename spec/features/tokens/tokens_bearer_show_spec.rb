# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Token bearer show', type: :feature do
  context 'valid' do
    let(:token) { '/argu/tokens/valid_bearer_token' }

    example 'new user visits bearer token' do
      as(:guest, location: token)

      wait_for(page).to have_content("You have been invited for the group 'Members'")

      click_button 'Log in'
      fill_in_registration_form

      accept_token
    end

    example 'logged out user visits bearer token' do
      as(:guest, location: token)

      wait_for(page).to have_content("You have been invited for the group 'Members'")

      click_button 'Log in'
      fill_in_login_form

      accept_token
    end

    example 'logged out member visits bearer token' do
      as(:guest, location: token)

      wait_for(page).to have_content("You have been invited for the group 'Members'")

      click_button 'Log in'

      fill_in_login_form 'member@example.com'

      accept_token result: :member_already
    end

    example 'user visits bearer token' do
      as('user1@example.com')
      visit "https://argu.localtest#{token}"

      accept_token
    end

    example 'member visits bearer token' do
      as('member@example.com')
      visit "https://argu.localtest#{token}"

      accept_token result: :member_already
    end
  end
end
