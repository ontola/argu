# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Page create', type: :feature do
  example 'user creates page' do
    as 'user1@example.com', location: '/argu/u/3/o'
    wait_for { page }.to have_content 'First page'
    find('h1', text: 'Organizations').click
    find('.CID-CollectionHeaderFloat .fa-plus').click

    wait_until_loaded

    fill_in field_name('http://schema.org/name'), with: 'My Website'
    fill_in field_name('https://argu.co/ns/core#shortname'), with: 'my_website'
    wait_for_terms_notice
    click_button 'Save'

    wait_for(page).to have_current_path('/my_website')
    wait_for { main_content.locator('[role="heading"]:has-text("My Website")').visible? }.to be_truthy
    expect(page).to have_title "My Website"

    visit('https://argu.localtest/argu/u/3/o')
    wait_for { main_content.locator('text=First page').visible? }.to be_truthy
    wait_for { main_content.locator('text=My Website').visible? }.to be_truthy
  end
end
