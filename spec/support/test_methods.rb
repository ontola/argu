# frozen_string_literal: true

require 'active_support'
require 'faraday/multipart'
require 'http-cookie'
require 'mailcatcher/api'
require 'empathy/emp_json/helpers/primitives'
require 'empathy/emp_json/helpers/hash'

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
    Capybara.current_session.driver.with_playwright_page do |page|
      page.expect_navigation do
        page.locator('button:has-text("Accept")').click
      end

      # @todo snackbars are shown, but the page is instantly reloaded.
      # This prevents the matcher from seeing the snackbar
      # case result
      # when :success
      #   wait_for { page }.to have_snackbar("You have joined the group 'Members'")
      # when :already_member
      #   wait_for { page }.to have_snackbar('You are already member of this group')
      # end

      navbar_tabs.locator('text=Holland')
      main_content.locator('text=Holland')

      verify_logged_in
    end
  end

  def login_body(actor, password, location)
    {
      '.' => {
        'http://schema.org/email' => actor,
        'https://ns.ontola.io/core#password' => password,
        'https://ns.ontola.io/core#redirectUrl' => location,
      }
    }.to_emp_json.to_json
  end

  def as(actor, location: '/argu/freetown', password: 'password')
    if actor != :guest
      visit 'https://argu.localtest/d/health'
      HEALTH_CHECKS.each do |check|
        expect(page.find_by_id(check.downcase.gsub(' ', '-'))).to have_text("pass")
      end
      cookies, csrf = authentication_values

      conn = Faraday.new(url: 'https://argu.localtest/argu/login') do |faraday|
        faraday.request :multipart
        faraday.adapter :net_http
      end
      response = conn.post do |req|
        req.headers.merge!(
          'Accept': 'application/empathy+json',
          'Content-Type': 'application/empathy+json',
          'Cookie' => HTTP::Cookie.cookie_value(cookies),
          'X-CSRF-Token' => csrf,
          'Website-IRI' => 'https://argu.localtest/argu'
        )
        req.body = login_body(actor, password, location)
      end

      expect(response.status).to eq(200)

      login_cookies = HTTP::CookieJar.new.parse(response.headers['set-cookie'], 'https://argu.localtest')
      Capybara.current_session.driver.with_playwright_page do |page|
        playwright_cookies = (cookies + login_cookies).map do |cookie|
          {
            "sameSite": "Strict",
            "name": cookie.name,
            "value": cookie.value,
            "domain": cookie.domain,
            "path": cookie.path,
            "expires": cookie.expires.to_f,
            "httpOnly": cookie.httponly,
            "secure": cookie.secure
          }
        end

        page.context.add_cookies(playwright_cookies)
      end
    end

    visit "https://argu.localtest#{location}"
  end

  def click_user_menu_button(button)
    scope = resource_selector('https://argu.localtest/argu/c_a', parent: navbar)
    scope.locator("button[title='User settings']").click(position: { x: 1, y: 1 })

    Capybara.current_session.driver.with_playwright_page do |page|
      page.locator('.CID-AppMenu').locator("text=#{button}").click
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
    wait_for { page }.to have_content label

    page.driver.with_playwright_page do |page|
      page.click("form button:has-text('#{label}')")
    end
  end

  def wait_until_loaded
    is_done = <<~JAVASCRIPT
      (() => {
        let noRequestsLeft = LRS.api.requestMap.size === 0;
        let doneRendering = (LRS.broadcastHandle || LRS.currentBroadcast || LRS.lastPostponed) === undefined;
        return noRequestsLeft && doneRendering;
      })();
    JAVASCRIPT

    wait_for do
      Capybara.current_session.driver.with_playwright_page do |page|
        page.evaluate(is_done)
      end
    end.to be_truthy
    sleep(0.2)
  end

  def login(email, password = 'password', modal: true, open_modal: true, two_fa: false)
    Capybara.current_session.driver.with_playwright_page do |page|
      page.locator('text=Log in / sign up')
    end
    wait_until_loaded
    Capybara.current_session.driver.with_playwright_page do |page|
      page.locator('text=Log in / sign up').click if modal && open_modal

      page.locator('text=Sign in or register')
    end

    fill_in_login_form email, password, modal: modal, two_fa: two_fa

    verify_logged_in
  end

  def logout(user: 'user_name_2')
    Capybara.current_session.driver.with_playwright_page do |page|
      page.expect_navigation do
        click_user_menu_button('Sign out')
      end
    end
  end

  def fill_in_login_form(
    email = 'user1@example.com',
    password = 'password',
    modal: true,
    two_fa: false,
    expect_reload: true
  )
    wait_for { page }.to have_content('Sign in or register')

    wait_until_loaded
    wrapper = modal ? ".MuiModal-root[role='presentation']" : 'form[action=\'/argu/u/session\']'
    wait_for { page }.to have_css(wrapper)

    within wrapper do
      wait_for { page }.to have_content('Email')
      fill_in placeholder: 'email@example.com', with: email, fill_options: {clear: :backspace}

      click_button 'Confirm'
    end

    wrapper = modal ? ".MuiModal-root[role='presentation']" : 'form[action=\'/argu/login\']'
    Capybara.current_session.driver.with_playwright_page do |page|
      wait_for { page.locator(wrapper).count }.to be 1
    end

    within wrapper do
      Capybara.current_session.driver.with_playwright_page do |page|
        page.fill(field_selector('https://ns.ontola.io/core#password'), password)
      end

      if two_fa
        click_button 'Continue'
      else
        Capybara.current_session.driver.with_playwright_page do |page|
          if expect_reload
            page.expect_navigation do
              click_button 'Continue'
            end
          else
            click_button 'Continue'
          end
        end
      end
    end

    return unless two_fa

    wait_for { page }.to have_content('Two factor authentication')
    otp = var_from_rails_console("EmailAddress.find_by(email: '#{email}').user.otp_secret.otp_code")
    Capybara.current_session.driver.with_playwright_page do |page|
      page.fill(field_selector('https://argu.co/ns/core#otp'), otp)
      if expect_reload
        page.expect_navigation do
          click_button 'Continue'
        end
      else
        click_button 'Continue'
      end
    end
  end

  def fill_in_markdown(locator, **args)
    fill_in(locator, **args)
  end

  def fill_in_registration_form(email = 'new_user@example.com')
    wait_for { page }.to have_content('Sign in or register')

    fill_in placeholder: 'email@example.com', with: email, fill_options: {clear: :backspace}

    click_button 'Confirm'

    wait_for_terms_notice

    Capybara.current_session.driver.with_playwright_page do |page|
      page.expect_navigation do
        click_button 'Confirm'
      end
    end
  end

  def finish_setup
    Capybara.current_session.driver.with_playwright_page do |page|
      page.locator('text=Welcome!')
    end
    within_dialog do
      fill_in field_name('https://argu.co/ns/core#name'), with: 'New user'
      wait_for { page }.to have_button 'Continue'
      click_button 'Continue'
    end
    Capybara.current_session.driver.with_playwright_page do |page|
      wait_for { page.locator('text=Welcome!').count }.to be 0
    end
  end

  def cancel_setup
    wait_for { page }.to have_content 'Welcome!'
    within_dialog do
      wait_for { page }.to have_button 'cancel'
      click_button 'cancel'
    end
    wait_for { page }.not_to have_content 'Welcome!'
  end

  def fill_in_select(name, with:)
    Capybara.current_session.driver.with_playwright_page do |page|
      input = page.locator("input.MuiInputBase-input[id='#{name}']")
      input.click

      with.split('').each { |key| input.type key }
      item_list = page.locator('ul[role="listbox"]')
      item_list.locator("li[role='option']:has-text('#{with}')").click
    end
  end

  def go_to_menu_item(text, menu: :actions, resource: page.current_url)
    wait_until_loaded
    resource_selector("#{resource}/menus/#{menu}").click
    wait_until_loaded
    wait_for { page }.to have_css('.MuiListItemText-primary', text: text)
    sleep(1)
    find('.MuiListItemText-primary', text: text, match: :prefer_exact).click
  end

  def next_id
    124
  end

  def go_to_user_page(tab: nil, user: 'user_name_2')
    click_user_menu_button('Settings')

    return if tab.nil?

    page.driver.with_playwright_page do |page|
      page.click("section[aria-label='Participate'] a:has-text('#{tab}')")
    end
  end

  def select_radio(label)
    find('label', text: label).click
  end

  def select_tab(tab)
    Capybara.current_session.driver.with_playwright_page do |page|
      tabs = page.locator('.MuiTabs-root')
      tabs.locator("text=#{tab}").click
    end
  end

  def switch_organization(organization)
    visit "https://argu.localtest/#{organization}"
  end

  def verify_logged_in(email = nil)
    Capybara.current_session.driver.with_playwright_page do |page|
      page.wait_for_selector("div[resource=\"#{current_tenant}/c_a\"]")
    end

    return unless email

    current_email_check = <<~JAVASCRIPT
      (() => {
        let value = LRS.store.getInternalStore().store.getField('#{current_tenant}/c_a', 'https://argu.co/ns/core#primaryEmail');
        return value && value.value;
      })();
    JAVASCRIPT

    expect(page.driver.evaluate_script(current_email_check)).to eq email
  end

  def verify_not_logged_in
    wait_for { page }.not_to have_css "div[resource=\"#{current_tenant}/c_a\"]"
    navbar.locator('text=Log in / sign up')
  end

  def wait_for_terms_notice
    wait_for { page }.to(
      have_content("By continuing you agree to our")
    )
  end

  def without
    current_scope = page.send(:scopes).pop
    yield
  ensure
    page.send(:scopes).push(current_scope)
  end

  def within_dialog
    within ".MuiModal-root[role='presentation']" do
      yield
    end
  end

  def expect_no_dialog
    wait_for { page }.not_to have_css(".MuiModal-root[role='presentation']")
  end

  def expect_email(email_name)
    @mailcatcher_expectation = true
    wait(20).for { send(email_name) }.to be_truthy, "#{email_name} has not been catched"
    @mailcatcher_expectation = false
  end
end
