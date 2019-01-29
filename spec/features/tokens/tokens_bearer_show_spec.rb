# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Token bearer show', type: :feature do
  context 'valid' do
    let(:token) { '/argu/tokens/valid_bearer_token' }

    example 'new user visits bearer token' do
      as(:guest, location: token)

      fill_in_registration_form

      expect_joined
    end

    example 'logged out user visits bearer token' do
      as(:guest, location: token)

      fill_in_login_form

      expect_joined
    end

    example 'logged out member visits bearer token' do
      as(:guest, location: token)

      fill_in_login_form 'member@example.com'

      expect_member_already
    end

    example 'user visits bearer token' do
      as('user1@example.com')
      visit "https://app.argu.localtest#{token}"

      expect_joined
    end

    example 'member visits bearer token' do
      as('member@example.com')
      visit "https://app.argu.localtest#{token}"

      expect_member_already
    end
  end

  private

  def expect_joined
    wait(30).for(page).to have_content('Holland')
    expect(page).to have_snackbar("You have joined the group 'Members'")
    # @todo verify favorite exists
  end

  def expect_member_already
    wait(30).for(page).to have_content('Holland')
    expect(page).to have_snackbar('You are already member of this group')
    # @todo verify favorite exists
  end
end
