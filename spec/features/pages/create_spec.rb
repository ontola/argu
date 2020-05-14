# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Page create', type: :feature do
  example 'user creates page' do
    as 'user1@example.com', location: '/argu/u/fg_shortname3end/o'
    wait_for { page }.to have_content 'First page'
    wait_for { page }.to have_css('.ContainerHeader')
    container_header = page.find('.ContainerHeader')
    resource_selector(
      'https://argu.localtest/argu/u/fg_shortname3end/o',
      child: '.fa-plus',
      parent: container_header
    ).click

    wait_until_loaded

    fill_in 'http://schema.org/name', with: 'My Website'
    fill_in 'https://argu.co/ns/core#shortname', with: 'my_website'
    check 'I accept the terms of use'
    click_button 'Save'

    wait(30).for(page).to have_current_path('/my_website')
    wait_for { main_content }.to have_content 'My Website'
    expect(page).to have_title "My Website"

    visit('https://argu.localtest/argu/u/fg_shortname3end/o')
    wait_for { main_content }.to have_content 'First page'
    wait_for { main_content }.to have_content 'My Website'
  end
end
