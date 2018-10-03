require 'spec_helper'

RSpec.describe 'Token email show legacy', type: :feature do
  before do
    use_legacy_frontend
  end

  context 'valid token' do
    let(:token) { '/tokens/valid_email_token' }

    example 'new user visits token' do
      as(:guest, location: token)

      expect_joined
    end

    example 'other user visits token' do
      as('user1@example.com')
      visit "https://argu.localtest#{token}"

      expect(page).to have_content('OTHER EMAIL ADDRESS')
      expect(page).to have_content('add invitee@example.com')
      click_button 'Log out'

      expect(page).to have_content('Please login to accept this invitation')
      click_link 'Sign up with email'

      expect(page).not_to have_content('REGISTER OR LOG IN')
      within('#new_user') do
        fill_in 'user_email', with: 'invitee@example.com'
        fill_in 'user_password', with: 'password'
        fill_in 'user_password_confirmation', with: 'password'
        click_button 'Sign up'
      end

      expect(page).to have_content('WELCOME!')
      click_button 'Next'
      expect(page).to have_content('FINISH YOUR ACCOUNT')
      click_button 'Skip'

      expect_joined
    end

    example 'user with second email address visits token' do
      as('user1@example.com')
      visit "https://argu.localtest#{token}"

      expect(page).to have_content('OTHER EMAIL ADDRESS')
      click_button 'Add invitee@example.com'

      expect_joined
    end
  end

  context 'user token' do
    let(:token) { '/tokens/user_email_token' }

    example 'logged out user visits token' do
      as(:guest, location: token)

      expect(page).to have_content('Please login to accept this invitation')
      within('#new_user') do
        fill_in 'user_email', with: 'user1@example.com'
        fill_in 'user_password', with: 'password'
        click_button 'Log in'
      end

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

      expect(page).to have_content('OTHER EMAIL ADDRESS')
      expect(page).not_to have_content('add user1@example.com')

      click_button 'Log out'

      expect(page).to have_content('Please login to accept this invitation')
      within('#new_user') do
        fill_in 'user_email', with: 'user1@example.com'
        fill_in 'user_password', with: 'password'
        click_button 'Log in'
      end

      expect_joined
    end
  end

  context 'member token' do
    let(:token) { '/tokens/member_email_token' }

    example 'logged out member visits token' do
      as(:guest, location: token)

      expect(page).to have_content('Please login to accept this invitation')
      within('#new_user') do
        fill_in 'user_email', with: 'member@example.com'
        fill_in 'user_password', with: 'password'
        click_button 'Log in'
      end

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
    wait_for(page).to have_content('Holland')
    expect(page).to have_content("You have joined the group 'Members'")
    expect(page).not_to have_content('Add to my forums')
  end

  def expect_member_already
    wait_for(page).to have_content('Holland')
    expect(page).to have_content('You are already member of this group')
    expect(page).not_to have_content('Add to my forums')
  end
end
