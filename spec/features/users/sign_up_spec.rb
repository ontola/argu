# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sign up', type: :feature do
  let(:email) { 'new_user@example.com' }

  example 'register as user' do
    register_user

    visit set_password_email.links.last

    verify_logged_in
    set_new_password

    verify_logged_in
    expect_homepage

    logout
    login(email, 'new password')
    expect_homepage
  end

  example 'register as user and logout' do
    register_user

    logout

    verify_not_logged_in
    visit set_password_email.links.last

    verify_not_logged_in
    set_new_password

    wait_for { page }.to have_content('Sign in or register')
    login(email, 'new password')
    expect_homepage
  end

  example 'change email during registration' do
    as(:guest)
    wait_for { page }.to have_content 'Log in / sign up'
    page.click_link('Log in / sign up')

    wait_for { page }.to have_content('Sign in or register')

    fill_in placeholder: 'email@example.com', with: 'other_email@example.com'

    click_button 'Confirm'

    wait_for_terms_notice

    click_link 'cancel'

    fill_in_registration_form email

    expect_email(:set_password_email)
  end

  private

  def expect_homepage
    wait_for { page }.to have_current_path('/argu')
    wait_for { page }.to have_content('Do you have a good idea?')
  end

  def register_user
    as(:guest)
    wait_for { page }.to have_content 'Log in / sign up'
    page.click_link('Log in / sign up')

    fill_in_registration_form email

    finish_setup

    expect_email(:set_password_email)
  end

  def set_new_password
    wait_for { page }.to have_content 'Set your password'

    fill_in field_name('https://ns.ontola.io/core#password'), with: 'new password'
    fill_in field_name('https://ns.ontola.io/core#passwordConfirmation'), with: 'new password'
    click_button 'Save'

    wait_for { page }.to have_snackbar('Your password has been updated successfully.')
  end

  def set_password_email
    @set_password_email ||= mailcatcher_email(to: [email], subject: 'Set your password')
  end
end
