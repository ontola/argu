# frozen_string_literal: true

require 'active_support'
require 'http-cookie'
require 'mailcatcher/api'

module TestMethods # rubocop:disable Metrics/ModuleLength
  HEALTH_CHECKS = [
    'Redis connectivity', 'Backend connectivity', 'Backend data fetching', 'Web manifest', 'Bulk endpoint'
  ].freeze

  attr_writer :current_tenant

  def accept_terms
    wait_for { page }.to have_content 'Terms of use'
    click_button 'Accept'
    wait_for { page }.not_to have_content 'Terms of use'
  end

  def accept_token(result: :success)
    wait_for { page }.to have_button('Accept')
    wait_until_loaded
    click_button('Accept')

    # @todo snackbars are shown, but the page is instantly reloaded.
    # This prevents the matcher from seeing the snackbar
    # case result
    # when :success
    #   wait_for { page }.to have_snackbar("You have joined the group 'Members'")
    # when :already_member
    #   wait_for { page }.to have_snackbar('You are already member of this group')
    # end
    wait(30).for(page).to have_current_path('/argu/holland')
    wait_for { navbar_tabs }.to have_content 'Holland'
    wait_for { main_content }.to have_content('Holland')
    verify_logged_in
  end

  def login_body(actor, password, location)
    body = <<-FOO
    <http://purl.org/link-lib/targetResource> <http://schema.org/email> "#{actor}" .
    <http://purl.org/link-lib/targetResource> <https://ns.ontola.io/core#password> "#{password}" .
    <http://purl.org/link-lib/targetResource> <https://ns.ontola.io/core#redirectUrl> <#{location}> .
    FOO
    Faraday::UploadIO.new(StringIO.new(body), 'application/n-triples')
  end

  def as(actor, location: '/argu/freetown', password: 'password')
    if actor != :guest
      visit 'https://argu.localtest/d/health'
      HEALTH_CHECKS.each do |check|
        expect(page).to have_text("#{check} 🟩 pass")
      end
      cookies, csrf = authentication_values

      conn = Faraday.new(url: 'https://argu.localtest/argu/login') do |faraday|
        faraday.request :multipart
        faraday.adapter :net_http
      end
      response = conn.post do |req|
        req.headers.merge!(
          'Accept': 'application/hex+x-ndjson',
          'Content-Type': 'multipart/form-data',
          'Cookie' => HTTP::Cookie.cookie_value(cookies),
          'X-CSRF-Token' => csrf,
          'Website-IRI' => 'https://argu.localtest/argu'
        )
        req.body = {'<http://purl.org/link-lib/graph>' => login_body(actor, password, location)}
      end

      expect(response.status).to eq(200)

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
    within application_menu do
      click_link button
    end
  end

  def current_tenant
    @current_tenant || 'https://argu.localtest/argu'
  end

  def authentication_values
    response = Faraday.get('https://argu.localtest/argu')

    expect(response.status).to eq(200)
    cookies = HTTP::CookieJar.new.parse(response.headers['set-cookie'], 'https://argu.localtest')
    csrf = response.body.match(/<meta name=\"csrf-token\" content=\"(.*)\">/)[1]

    [cookies, csrf]
  end

  def expand_form_group(label)
    wait_for { page }.to have_css('form')
    within 'form' do
      click_button(label)
    end
  end

  def wait_until_loaded
    is_done =
      'return LRS.api.requestMap.size === 0 && '\
      '(LRS.broadcastHandle || LRS.currentBroadcast || LRS.lastPostponed) === undefined;'
    wait(30).for { page.execute_script(is_done) }.to be_truthy
    sleep(0.5)
  end

  def login(email, password = 'password', modal: true, open_modal: true, two_fa: false)
    wait_for { page }.to have_content 'Log in / sign up'

    page.click_link('Log in / sign up') if modal && open_modal

    wait_for { page }.to have_content 'Sign in or register'

    fill_in_login_form email, password, modal: modal, two_fa: two_fa

    verify_logged_in
  end

  def logout
    click_application_menu_button('Sign out')
  end

  def fill_in_login_form(email = 'user1@example.com', password = 'password', modal: true, two_fa: false)
    wait_for { page }.to have_content('Sign in or register')

    wrapper = modal ? "[role='dialog']" : 'form.Form'
    within wrapper do
      wait_for(page).to have_content('Email')
      fill_in placeholder: 'email@example.com', with: email, fill_options: {clear: :backspace}

      click_button 'Confirm'

      wait_for(page).to have_content('Password')
      fill_in field_name('https://ns.ontola.io/core#password'), with: password

      click_button 'Continue'
    end

    return unless two_fa

    wait_for{ page }.to have_content('Two factor authentication')
    otp = var_from_rails_console("EmailAddress.find_by(email: '#{email}').user.otp_secret.otp_code")
    fill_in field_name('https://argu.co/ns/core#otp'), with: otp, fill_options: {clear: :backspace}
    click_button 'Continue'
  end

  def fill_in_markdown(locator, **args)
    fill_in(locator, args)
  end

  def fill_in_registration_form(email = 'new_user@example.com')
    wait_for { page }.to have_content('Sign in or register')

    fill_in placeholder: 'email@example.com', with: email, fill_options: {clear: :backspace}

    click_button 'Confirm'

    wait_for_terms_notice

    click_button 'Confirm'
  end

  def fill_in_select(name = nil, with: nil, selector: nil)
    wait_for { page }.to have_css("div[aria-labelledby='#{name}-label']")
    within "div[aria-labelledby='#{name}-label']" do
      click_button
      select = lambda do
        input_field = find('.Input').native
        with.split('').each { |key| input_field.send_keys key } if with
        selector ||= /#{with}/
        wait_for { page }.to have_css('.SelectItem', text: selector)
        find('.SelectItem', text: selector).click
      end
      select.call
    end
  end

  def go_to_menu_item(text, menu: :actions, resource: page.current_url)
    wait_until_loaded
    resource_selector("#{resource}/menus/#{menu}").click
    wait_until_loaded
    yield if block_given?
    wait_for { page }.to have_css('.MuiListItem-button', text: text)
    sleep(1)
    find('.MuiListItem-button', text: text, match: :prefer_exact).click
  end

  def go_to_user_page(tab = nil)
    wait_until_loaded

    within(resource_selector("#{current_tenant}/c_a")) do
      find('.MuiButton-root').click
    end

    return if tab.nil?

    wait_for { page }.to have_button tab
    click_button tab
  end

  def select_radio(label)
    find('label', text: label).click
  end

  def select_tab(tab)
    wait_for { page }.to have_css('.MuiTabs-root')
    wait_until_loaded
    within '.MuiTabs-root' do
      click_button tab
    end
  end

  def switch_organization(organization)
    visit "https://argu.localtest/#{organization}"
  end

  def verify_logged_in(email = nil)
    wait(30).for { page }.to have_css "div[resource=\"#{current_tenant}/c_a\"]"

    return unless email

    current_email_check = "match = LRS.store.find(window[Symbol.for('rdfFactory')].namedNode('#{current_tenant}/c_a'), window[Symbol.for('rdfFactory')].namedNode('https://argu.co/ns/core#primaryEmail')); "\
      "return match && match.object.value;"
    expect(page.execute_script(current_email_check)).to eq(email)
  end

  def verify_not_logged_in
    wait_for { page }.not_to have_css "div[resource=\"#{current_tenant}/c_a\"]"
    wait_for { navbar }.to have_content 'Log in / sign up'
  end

  def wait_for_terms_notice
    wait_for { page }.to(
      have_content("By continuing you agree to our\nTerms of use\nand our\nPrivacy policy\n.")
    )
  end

  def expect_email(email_name)
    @mailcatcher_expectation = true
    wait(20).for { send(email_name) }.to be_truthy, "#{email_name} has not been catched"
    @mailcatcher_expectation = false
  end
end
