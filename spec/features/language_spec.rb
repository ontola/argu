# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Language', type: :feature do
  example 'Guest changes language' do
    # @todo Currently there is no way to go to the language page as guest
    as :guest, location: '/argu/user/language'

    Capybara.current_session.driver.with_playwright_page do |page|
      wait_for { page.locator('input[value="English"]').visible? }.to be_truthy
    end
    fill_in_select(field_name('http://schema.org/language'), with: 'Nederlands')

    Capybara.current_session.driver.with_playwright_page do |page|
      page.expect_navigation(waitUntil: 'networkidle') do
        page.locator('text=Save').click
      end
    end
    Capybara.current_session.driver.with_playwright_page do |page|
      page.expect_navigation(waitUntil: 'networkidle')
    end

    wait_for {
      Capybara.current_session.driver.with_playwright_page do |page|
          page.locator('text=Taal instellen').visible?
      end
    }.to be_truthy
    wait_for {
      Capybara.current_session.driver.with_playwright_page do |page|
        page.locator('input[value="Nederlands"]').visible?
      end
    }.to be_truthy
  end

  example 'User changes language' do
    as 'user1@example.com'

    Capybara.current_session.driver.with_playwright_page do |page|
      click_user_menu_button('Set language')

      wait_for { page.locator('input[value="English"]').visible? }.to be_truthy

      page.expect_navigation do
        fill_in_select(field_name('http://schema.org/language'), with: 'Nederlands')
        page.locator('text=Save').click
      end
    end
    Capybara.current_session.driver.with_playwright_page do |page|
      page.expect_navigation(waitUntil: 'networkidle')
    end

    wait_for {
      Capybara.current_session.driver.with_playwright_page do |page|
        page.locator('text=Taal instellen').visible?
      end
    }.to be_truthy
    wait_for {
      Capybara.current_session.driver.with_playwright_page do |page|
        page.locator('input[value="Nederlands"]').visible?
      end
    }.to be_truthy
  end
end
