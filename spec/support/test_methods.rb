# frozen_string_literal: true

require 'mailcatcher/api'

module TestMethods
  def as(actor, location: '/argu/freetown', password: 'password')
    visit "https://#{use_legacy_frontend? ? '' : 'app.'}argu.localtest#{location}"
    return if actor == :guest

    use_legacy_frontend? ? login_legacy(actor, password) : login(actor, password)
  end

  def wait_until_loaded
    wait_for { page.evaluate_script('LRS.api.requestMap.size === 0') }.to be_truthy
  end

  def login(email, password = 'password')
    wait_for(page).to have_content 'Log in / registreer'

    page.click_link('Log in / registreer')

    expect(page).to have_content 'inloggen of registreren'

    fill_in_login_form email, password

    verify_logged_in
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

  def logout
    current_user_section('.SideBarCollapsible__toggle').click
    wait_for { current_user_section }.to have_content 'Sign out'
    current_user_section(:link, 'Sign out').click
  end

  def fill_in_login_form(email = 'user1@example.com', password = 'password')
    wait_for(page).to have_content('inloggen of registreren')

    fill_in placeholder: 'email@example.com', with: email, fill_options: {clear: :backspace}

    click_button 'Ga verder'

    fill_in type: :password, with: password

    click_button 'Verder'
  end

  def fill_in_registration_form(email = 'new_user@example.com')
    wait_for(page).to have_content('inloggen of registreren')

    fill_in placeholder: 'email@example.com', with: email, fill_options: {clear: :backspace}

    click_button 'Ga verder'

    expect(page).to(
      have_content('Door je te registreren ga je akkoord met de algemene voorwaarden en de privacy policy.')
    )

    click_button 'Bevestig'
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
    scope ? within(scope, &select) : select.call
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

  def expect_email(email_name)
    @mailcatcher_expectation = true
    wait(20).for { send(email_name) }.to be_truthy, "#{email_name} has not been catched"
    @mailcatcher_expectation = false
  end
end
