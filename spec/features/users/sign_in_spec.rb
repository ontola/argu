# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sign in', type: :feature do
  it 'authenticates a valid user' do
    as('user1@example.com')
    wait_for { page }.to have_content 'Fg motion title 8end'
  end

  it 'denies a user with wrong email' do
    as(:guest)
    page.click_link('Log in / registreer')

    fill_in placeholder: 'email@example.com', with: 'wrong@example.com'

    click_button 'Ga verder'

    expect(page).to have_content 'Door je te registreren ga je akkoord met de algemene voorwaarden en de privacy policy.'

    click_button 'Terug'

    fill_in_login_form 'user1@example.com'

    verify_logged_in

    wait_for { page }.to have_content 'Fg motion title 8end'
  end

  it 'denies a user with wrong password' do
    as(:guest)
    wait_for(page).to have_content('Log in / registreer')
    page.click_link('Log in / registreer')

    fill_in_login_form 'user1@example.com', 'wrong_password'

    # Wrong password behaviour
  end
end
