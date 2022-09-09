# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Page create', type: :feature do
  example 'user creates page' do
    self.current_tenant = 'https://argu.localtest/other_page'
    as 'user1@example.com', location: '/other_page'
    self.current_tenant = 'https://argu.localtest/argu'
    as 'user1@example.com', location: '/argu/u/3/o'
    wait_for { main_content.locator('text=Other page').visible? }.to be_truthy
    find('h1', text: 'Communities').click
    collection_float_button('Get started').click

    wait_until_loaded

    fill_in field_name('http://schema.org/name'), with: 'My Website'
    fill_in field_name('https://argu.co/ns/core#shortname'), with: 'my_website'
    wait_for_terms_notice
    click_button 'Save'

    wait_for(page).to have_current_path('/my_website')

    wait_for { page }.to have_content('This item is hidden')
    expect(main_content.locator('[role="heading"]:has-text("My Website")').visible?).not_to be_truthy
    playwright_page.locator('main a:has-text("Log in / sign up")').click
    fill_in_login_form 'user1@example.com', 'password', modal: true
    wait_for { main_content.locator('[role="heading"]:has-text("My Website")').visible? }.to be_truthy
    expect(page).to have_title "My Website"

    visit('https://argu.localtest/argu/u/3/o')
    wait_for { main_content.locator('text=Other page').visible? }.to be_truthy
    wait_for { main_content.locator('text=My Website').visible? }.to be_truthy
  end
end
