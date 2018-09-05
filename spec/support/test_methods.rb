# frozen_string_literal: true

require 'mailcatcher/api'

module TestMethods
  def as(actor, location: '/argu/freetown', password: 'password')
    visit "https://app.argu.localtest#{location}"
    login(actor, password) unless actor == :guest
  end

  def login(email, password = 'password')
    page.click_link('Log in / registreer')

    expect(page).to have_content 'inloggen of registreren'

    fill_in placeholder: 'email@example.com', with: email

    click_button 'Ga verder'

    fill_in type: :password, with: password

    click_button 'Verder'

    verify_logged_in
    expect(page).not_to have_content 'inloggen of registreren'
  end

  # Helper to aid in picking an option in a Selectize dropdown
  def fill_in_select(scope = nil, with: nil, selector: nil)``
    select = lambda do
      input_field = find('.Select-control .Select-input input').native
      input_field.send_keys with
      selector ||= /#{with}/
      wait_for { page }.to have_css('.Select-option')
      find('.Select-option', text: selector).click
    end
    if scope
      within(scope, &select)
    else
      select.call
    end
  end

  def verify_logged_in
    wait_for { page }.to have_css 'div[resource="https://app.argu.localtest/c_a"]'
  end
end
