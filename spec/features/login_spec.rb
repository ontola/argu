# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Login', type: :feature do
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

    click_button 'Bevestig'

    wait_for { page }.to have_content 'Fg motion title 8end'

    verify_logged_in
  end

  it 'denies a user with wrong password' do
    as(:guest)
    page.click_link('Log in / registreer')

    fill_in placeholder: 'email@example.com', with: 'user1@example.com'

    click_button 'Ga verder'

    fill_in type: :password, with: 'wrong'

    click_button 'Verder'

    # Wrong password behaviour
  end
end
