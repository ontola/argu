# frozen_string_literal: true

require 'active_support'
require 'http-cookie'
require 'mailcatcher/api'

module TestMethods # rubocop:disable Metrics/ModuleLength
  attr_writer :current_tenant

  def accept_terms
    wait_for { page }.to have_content 'Terms of use'
    click_button 'Accept'
    wait_for { page }.not_to have_content 'Terms of use'
  end

  def accept_token(result: :success)
    wait_for { page }.to have_button('Accept')
    click_button('Accept')

    case result
    when :success
      # @todo snackbars are shown, but the page is instantly reloaded.
      # This prevents the matcher from seeing the snackbar
      # wait_for { page }.to have_snackbar("You have joined the group 'Members'")
    when :already_member
      wait_for { page }.to have_snackbar('You are already member of this group')
    end
    wait(30).for(page).to have_current_path('/argu/holland')
    wait_for { page }.to have_content('Holland')
    verify_logged_in
  end

  def as(actor, location: '/argu/freetown', password: 'password')
    if actor != :guest
      visit 'https://argu.localtest/wait_for_login'
      cookies, csrf = authentication_values

      response = Faraday.post(
        'https://argu.localtest/login',
        {email: actor, password: password, r: location},
        'Cookie' => HTTP::Cookie.cookie_value(cookies),
        'X-CSRF-Token' => csrf,
        'Website-IRI' => 'https://argu.localtest/argu'
      )

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['status']).to eq('SIGN_IN_LOGGED_IN')

      cookies.each do |cookie|
        page.driver.browser.manage.add_cookie(name: cookie.name, value: cookie.value)
      end
    end

    visit "https://argu.localtest#{location}"
  end

  def click_application_menu_button(button)
    application_menu_button.click
    wait_until_loaded
    wait_for { page }.to have_css '.AppMenu'
    wait_for { application_menu }.to have_content button
    sleep 1
    click_link button
  end

  def current_tenant
    @current_tenant || 'https://argu.localtest/argu'
  end

  def authentication_values
    response = Faraday.get('https://argu.localtest/argu')

    cookies = HTTP::CookieJar.new.parse(response.headers['set-cookie'], 'https://argu.localtest')
    csrf = response.body.match(/<meta name=\"csrf-token\" content=\"(.*)\">/)[1]

    expect(response.status).to eq(200)
    [cookies, csrf]
  end

  def expand_form_group(label)
    click_button(label)
  end

  def wait_until_loaded
    is_done =
      'return LRS.api.requestMap.size === 0 && '\
      '(LRS.broadcastHandle || LRS.currentBroadcast || LRS.lastPostponed) === undefined;'
    wait_for { page.execute_script(is_done) }.to be_truthy
  end

  def login(email, password = 'password', modal: true, open_modal: true)
    wait_for { page }.to have_content 'Log in / sign up'

    page.click_link('Log in / sign up') if modal && open_modal

    wait_for { page }.to have_content 'login or register'

    fill_in_login_form email, password, modal: modal

    verify_logged_in
  end

  def logout
    click_application_menu_button('Sign out')
  end

  def fill_in_login_form(email = 'user1@example.com', password = 'password', modal: true)
    wait_for { page }.to have_content('login or register')

    wrapper = modal ? "[role='dialog']" : "form[action='/users']"
    within wrapper do
      fill_in placeholder: 'email@example.com', with: email, fill_options: {clear: :backspace}

      click_button 'Confirm'

      fill_in type: :password, with: password

      click_button 'Continue'
    end
  end

  def fill_in_markdown(locator, **args)
    wait_for { page }.to have_button('Opmaak')
    id = [args[:parent] || page.current_url, locator].join('.')
    click_button 'Opmaak'
    fill_in(id, args.except(:parent).merge(fill_options: {clear: :backspace}))
  end

  def fill_in_registration_form(email = 'new_user@example.com')
    wait_for { page }.to have_content('login or register')

    fill_in placeholder: 'email@example.com', with: email, fill_options: {clear: :backspace}

    click_button 'Confirm'

    wait_for_terms_notice

    click_button 'Confirm'
  end

  def fill_in_select(name = nil, with: nil, selector: nil)
    select = lambda do
      input_field = find("input[id='#{name}-input'].Input").native
      with.split('').each { |key| input_field.send_keys key }
      selector ||= /#{with}/
      wait_for { page }.to have_css('.SelectItem', text: selector)
      find('.SelectItem', text: selector).click
    end
    select.call
  end

  def go_to_menu_item(text, menu: :actions, resource: page.current_url)
    wait_until_loaded
    resource_selector("#{resource}/menus/#{menu}").click
    wait_until_loaded
    yield if block_given?
    wait_for { page }.to have_css('.MuiListItem-button', text: text)
    sleep(1)
    find('.MuiListItem-button', text: text).click
  end

  def go_to_user_page(tab = nil)
    within(resource_selector("#{current_tenant}/c_a")) do
      find('.NavbarLink__link').click
    end

    return if tab.nil?

    wait_for { page }.to have_link tab
    click_link tab
  end

  def select_radio(label)
    find('label', text: label).click
  end

  def select_tab(tab)
    wait_for { page }.to have_css('.MuiTabs-root')
    within '.MuiTabs-root' do
      click_link tab
    end
  end

  def switch_organization(organization)
    visit "https://argu.localtest/#{organization}"
  end

  def verify_logged_in(email = nil)
    wait(30).for { page }.to have_css "div[resource=\"#{current_tenant}/c_a\"]"

    return unless email

    current_email_check = "match = LRS.store.find(LRS.namespaces.app('c_a'), LRS.namespaces.argu('primaryEmail')); "\
      "return match && match.object.value;"
    expect(page.execute_script(current_email_check)).to eq(email)
  end

  def verify_not_logged_in
    wait_for { page }.not_to have_css "div[resource=\"#{current_tenant}/c_a\"]"
  end

  def wait_for_terms_notice
    wait_for { page }.to(
      have_content("Door je te registreren ga je akkoord met de\n algemene voorwaarden \nen de\n privacy policy\n.")
    )
  end

  def expect_email(email_name)
    @mailcatcher_expectation = true
    wait(20).for { send(email_name) }.to be_truthy, "#{email_name} has not been catched"
    @mailcatcher_expectation = false
  end
end
