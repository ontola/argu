# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Language', type: :feature do
  example 'Guest changes language' do
    # @todo Currently there is no way to go to the language page as guest
    as :guest, location: '/argu/user/language'

    wait_for { playwright_page.locator('input[value="English"]').visible? }.to be_truthy
    fill_in_select(field_name('http://schema.org/language'), with: 'Nederlands')

    playwright_page.expect_navigation(waitUntil: 'networkidle') do
      playwright_page.locator('text=Save').click
    end
    playwright_page.expect_navigation(waitUntil: 'networkidle')

    wait_for {
      playwright_page.locator('text=Taal instellen').visible?
    }.to be_truthy
    wait_for {
      playwright_page.locator('input[value="Nederlands"]').visible?
    }.to be_truthy
  end

  example 'User changes language' do
    as 'user1@example.com'

    click_user_menu_button('Set language')

    wait_for { playwright_page.locator('input[value="English"]').visible? }.to be_truthy

    playwright_page.expect_navigation do
      fill_in_select(field_name('http://schema.org/language'), with: 'Nederlands')
      playwright_page.locator('text=Save').click
    end
    playwright_page.expect_navigation(waitUntil: 'networkidle')

    wait_for {
      playwright_page.locator('text=Taal instellen').visible?
    }.to be_truthy
    wait_for {
      playwright_page.locator('input[value="Nederlands"]').visible?
    }.to be_truthy
  end
end
