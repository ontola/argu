# frozen_string_literal: true

require 'mailcatcher/api'

module TestMethods # rubocop:disable Metrics/ModuleLength
  attr_writer :current_tenant

  def accept_terms
    wait_for(page).to have_content 'Terms of use'
    click_button 'Accept'
  end

  def accept_token(result: :success)
    wait_for(page).to have_button('Accept')
    click_button('Accept')

    case result
    when :success
      # @todo snackbars are shown, but the page is instantly reloaded.
      # This prevents the matcher from seeing the snackbar
      # wait_for(page).to have_snackbar("You have joined the group 'Members'")
    when :already_member
      wait_for(page).to have_snackbar('You are already member of this group')
    end
    wait(30).for(page).to have_current_path('/argu/holland')
    wait_for(page).to have_content('Holland')
    verify_logged_in
  end

  def as(actor, location: '/argu/freetown', password: 'password')
    visit "https://#{use_legacy_frontend? ? '' : 'app.'}argu.localtest#{location}"
    return if actor == :guest
    use_legacy_frontend? ? login_legacy(actor, password) : login(actor, password)
  end

  def click_application_menu_button(button)
    application_menu_button.click
    wait_until_loaded
    wait_for(page).to have_css '.AppMenu'
    wait_for { application_menu }.to have_content button
    click_link button
  end

  def current_tenant
    @current_tenant || 'https://app.argu.localtest/argu'
  end

  def wait_until_loaded
    is_done =
      'return LRS.api.requestMap.size === 0 && '\
      '(LRS.broadcastHandle || LRS.currentBroadcast || LRS.lastPostponed) === undefined;'
    wait_for { page.execute_script(is_done) }.to be_truthy
  end

  def login(email, password = 'password', modal: true)
    wait_for { page }.to have_content 'Log in / sign up'

    page.click_link('Log in / sign up') unless current_path.include?('/u/sign_in')

    wait_for(page).to have_content 'login or register'

    fill_in_login_form email, password, modal: modal

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
    click_application_menu_button('Sign out')
  end

  def fill_in_login_form(email = 'user1@example.com', password = 'password', modal: true)
    wait_for(page).to have_content('login or register')

    wrapper = modal ? '.Modal__portal' : "form[action='/users']"
    within wrapper do
      fill_in placeholder: 'email@example.com', with: email, fill_options: {clear: :backspace}

      click_button 'Confirm'

      fill_in type: :password, with: password

      click_button 'Continue'
    end
  end

  def fill_in_registration_form(email = 'new_user@example.com')
    wait_for(page).to have_content('login or register')

    fill_in placeholder: 'email@example.com', with: email, fill_options: {clear: :backspace}

    click_button 'Confirm'

    wait_for_terms_notice

    click_button 'Confirm'
  end

  def fill_in_select(name = nil, with: nil, selector: nil)
    return fill_in_select_legacy(name, with, selector) if use_legacy_frontend?

    select = lambda do
      input_field = find("input[id='#{name}-input'].Input").native
      with.split('').each { |key| input_field.send_keys key }
      selector ||= /#{with}/
      wait_for { page }.to have_css('.SelectItem', text: selector)
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
      wait_for { page }.to have_css('.Select-option', text: selector)
      find('.Select-option', text: selector).click
    end
    scope ? within(scope, &select) : select.call
  end

  def go_to_menu_item(text, menu: :actions, resource: page.current_url)
    wait_until_loaded
    resource_selector("#{resource}/menus/#{menu}").click
    wait_until_loaded
    yield if block_given?
    wait_for(page).to have_css('.MuiListItem-button', text: text)
    sleep(1)
    find('.MuiListItem-button', text: text).click
  end

  def select_tab(tab)
    wait_for(page).to have_css('.MuiTabs-root')
    within '.MuiTabs-root' do
      click_link tab
    end
  end

  def switch_organization(organization)
    visit "https://app.argu.localtest/#{organization}"
  end

  def verify_logged_in
    wait(30).for { page }.to have_css "div[resource=\"#{current_tenant}/c_a\"]"
  end

  def verify_not_logged_in
    wait_for { page }.not_to have_css "div[resource=\"#{current_tenant}/c_a\"]"
  end

  def visit(url)
    return super if use_legacy_frontend?

    super(url.gsub('https://argu', 'https://app.argu'))
  end

  def wait_for_terms_notice
    wait_for(page).to(
      have_content("Door je te registreren ga je akkoord met de\n algemene voorwaarden \nen de\n privacy policy\n.")
    )
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
