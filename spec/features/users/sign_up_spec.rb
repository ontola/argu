# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sign up', type: :feature do
  let(:email) { 'new_user@example.com' }

  example 'register as user' do
    as(:guest)
    wait_for(page).to have_content 'Log in / sign up'
    page.click_link('Log in / sign up')

    fill_in_registration_form email

    expect_email(:set_password_email)

    visit set_password_email.links.last

    wait_for(page).to have_content 'Choose a password'

    fill_in 'https://argu.co/ns/core#password', with: 'new password'
    fill_in 'https://argu.co/ns/core#passwordConfirmation', with: 'new password'
    click_button 'Save'

    verify_logged_in
    wait_for(page).to have_snackbar('Your password has been updated successfully.')
    expect(page).to have_content('Welcome!')

    logout
    login(email, 'new password')
  end

  example 'change email during registration' do
    as(:guest)
    wait_for(page).to have_content 'Log in / sign up'
    page.click_link('Log in / sign up')

    wait_for(page).to have_content('login or register')

    fill_in placeholder: 'email@example.com', with: 'other_email@example.com'

    click_button 'Confirm'

    expect(page).to(
      have_content('Door je te registreren ga je akkoord met de algemene voorwaarden en de privacy policy.')
    )

    click_button 'back'

    fill_in_registration_form email

    expect_email(:set_password_email)
  end

  private

  def set_password_email
    @set_password_email ||= mailcatcher_email(to: [email], subject: 'Set your password')
  end
end
