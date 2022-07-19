# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sign in', type: :feature do
  it 'authenticates a valid user' do
    as(:guest)
    wait_for { page }.to have_content('Log in / sign up')
    page.click_link('Log in / sign up')

    fill_in_login_form 'user1@example.com', 'password'

    verify_logged_in
  end

  it 'authenticates a user with two factor' do
    as(:guest)
    wait_for { page }.to have_content('Log in / sign up')
    page.click_link('Log in / sign up')

    fill_in_login_form '2fa@example.com', 'password', two_fa: true

    verify_logged_in
  end

  it 'denies a user with wrong two factor' do
    as(:guest)
    wait_for { page }.to have_content('Log in / sign up')
    page.click_link('Log in / sign up')

    fill_in_login_form '2fa@example.com', 'password', expect_reload: false

    wait_for{ page }.to have_content('Two factor authentication')

    fill_in field_name('https://argu.co/ns/core#otp'),
            with: '123456',
            fill_options: {clear: :backspace}

    click_button 'Continue'

    wait_for { page }.to have_content 'The authentication code is incorrect.'
  end

  it 'denies a user with wrong email' do
    as(:guest)
    wait_for { page }.to have_content('Log in / sign up')
    page.click_link('Log in / sign up')

    fill_in placeholder: 'email@example.com', with: 'wrong@example.com'

    click_button 'Confirm'

    wait_for_terms_notice

    click_button 'cancel'

    fill_in_login_form 'user1@example.com'

    verify_logged_in

    wait_for { page }.to have_content 'Freetown_motion-title'
  end

  it 'denies a user with wrong password' do
    as(:guest)
    wait_for { page }.to have_content('Log in / sign up')
    page.click_link('Log in / sign up')

    fill_in_login_form 'user1@example.com', 'wrong_password', expect_reload: false

    wait_for { page }.to have_content 'Invalid password'
  end
end
