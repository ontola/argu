# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sign in', type: :feature do
  it 'authenticates a valid user' do
    as('user1@example.com')
    wait_for { page }.to have_content 'Fg motion title 9end'
  end

  it 'denies a user with wrong email' do
    as(:guest)
    wait_for { page }.to have_content('Log in / sign up')
    page.click_link('Log in / sign up')

    fill_in placeholder: 'email@example.com', with: 'wrong@example.com'

    click_button 'Confirm'

    wait_for_terms_notice

    click_button 'back'

    fill_in_login_form 'user1@example.com'

    verify_logged_in

    wait_for { page }.to have_content 'Fg motion title 9end'
  end

  it 'denies a user with wrong password' do
    as(:guest)
    wait_for { page }.to have_content('Log in / sign up')
    page.click_link('Log in / sign up')

    fill_in_login_form 'user1@example.com', 'wrong_password'

    # @todo Wrong password behaviour
  end
end
