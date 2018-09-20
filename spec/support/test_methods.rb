# frozen_string_literal: true

require 'mailcatcher/api'

module TestMethods
  def as(actor, location: '/argu/freetown', password: 'password')
    visit "https://#{use_legacy_frontend? ? '' : 'app.'}argu.localtest#{location}"
    return if actor == :guest
    use_legacy_frontend? ? login_legacy(actor, password) : login(actor, password)
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

  def login_legacy(email, password = 'password')
    page.click_link('Log in')

    expect(page).to have_css('.modal-opened')

    within('.modal #new_user') do
      fill_in 'user_email', with: email
      fill_in 'user_password', with: password
      click_button 'Log in'
    end
  end

  # Helper to aid in picking an option in a Selectize dropdown
  def fill_in_select(scope = nil, with: nil, selector: nil)
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

  def visit(url)
    return super if use_legacy_frontend?
    super(url.gsub('https://argu', 'https://app.argu'))
  end

  def use_legacy_frontend
    @use_legacy_frontend = true
  end

  def use_legacy_frontend?
    @use_legacy_frontend == true
  end
end
