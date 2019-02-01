# frozen_string_literal: true

require 'mailcatcher/api'

module TestMethods # rubocop:disable Metrics/ModuleLength
  def accept_terms
    wait_for(page).to have_content 'Terms of use'
    click_button 'Accept'
  end

  def as(actor, location: '/argu/freetown', password: 'password')
    visit "https://#{use_legacy_frontend? ? '' : 'app.'}argu.localtest#{location}"
    return if actor == :guest

    use_legacy_frontend? ? login_legacy(actor, password) : login(actor, password)
  end

  def wait_until_loaded
    is_done =
      'return LRS.api.requestMap.size === 0 && '\
      '(LRS.broadcastHandle || LRS.currentBroadcast || LRS.lastPostponed) === undefined;'
    wait_for { page.execute_script(is_done) }.to be_truthy
  end

  def login(email, password = 'password')
    wait_for(page).to have_content 'Log in / sign up'

    page.click_link('Log in / sign up')

    expect(page).to have_content 'login or register'

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
    wait_for(page).to have_content('login or register')

    fill_in placeholder: 'email@example.com', with: email, fill_options: {clear: :backspace}

    click_button 'Confirm'

    fill_in type: :password, with: password

    click_button 'Continue'
  end

  def fill_in_registration_form(email = 'new_user@example.com')
    wait_for(page).to have_content('login or register')

    fill_in placeholder: 'email@example.com', with: email, fill_options: {clear: :backspace}

    click_button 'Confirm'

    expect(page).to(
      have_content('Door je te registreren ga je akkoord met de algemene voorwaarden en de privacy policy.')
    )

    click_button 'Confirm'
  end

  def fill_in_select(name = nil, with: nil, selector: nil)
    return fill_in_select_legacy(name, with, selector) if use_legacy_frontend?

    select = lambda do
      input_field = find("input[name='#{name}'].Field__input--select").native
      input_field.send_keys with
      selector ||= /#{with}/
      wait_for { page }.to have_css('.SelectItem')
      find('.SelectItem', text: selector).click
    end
    select.call
  end

  # Helper to aid in picking an option in a Selectize dropdown
  def fill_in_select_legacy(scope, with, selector)
    select = lambda do
      input_field = find('.Select-control .Select-input input').native
      input_field.send_keys with
      selector ||= /#{with}/
      wait_for { page }.to have_css('.Select-option')
      find('.Select-option', text: selector).click
    end
    scope ? within(scope, &select) : select.call
  end

  def go_to_menu_item(text, menu: :actions, resource: page.current_url)
    wait_until_loaded
    resource_selector("#{resource}/menus/#{menu}").click
    wait_until_loaded
    yield if block_given?
    wait_for(page).to have_css('.DropdownLink', text: text)
    find('.DropdownLink', text: text).click
  end

  def select_tab(tab)
    wait_for(page).to have_css('.TabBar')
    within '.TabBar' do
      click_link tab
    end
  end

  def switch_organization(organization)
    find('.NavBarContent__switcher .SideBarCollapsible__toggle').click
    expect(sidebar).to have_content organization
    expect(main_content).not_to have_content organization
    click_link organization
    expect(main_content).to have_content organization
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
