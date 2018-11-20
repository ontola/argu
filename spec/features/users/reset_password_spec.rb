# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User reset password', type: :feature do
  example 'guest resets password' do
    as(:guest, location: '/users/password/new')
    wait_for(page).to have_content('Forgotten password?')
    fill_in placeholder: 'email@example.com', with: 'user1@example.com'
    click_button 'Save'

    wait_for(page).to(
      have_content('You will receive an email shortly with instructions to reset your password')
    )
    expect(page).to have_content('login or register')
    expect(page.current_url).to include('/u/sign_in')
    expect_email(:password_reset_email)

    visit password_reset_email.links.last
    wait_for(page).to have_content('Choose a password')
    fill_in placeholder: 'At least 8 characters.', with: 'new password'
    fill_in placeholder: 'Same as above', with: 'new password'
    click_button 'Save'

    wait_for(page).to have_content('Your password has been updated successfully.')

    expect_email(:password_changed_email)

    login('user1@example.com', 'new password')
  end

  private

  def password_reset_email
    @password_reset_email ||= mailcatcher_email(to: ['user1@example.com'], subject: 'Password reset instructions')
  end

  def password_changed_email
    @password_changed_email ||= mailcatcher_email(to: ['user1@example.com'], subject: 'Your password has been updated')
  end
end
