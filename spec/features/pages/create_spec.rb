# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Page create', type: :feature do
  example 'user creates page' do
    as 'user1@example.com'
    click_application_menu_button('My Argu websites')
    wait_for(page).to have_content 'No items yet'
    click_link 'New website'
    wait_until_loaded

    fill_in 'http://xmlns.com/foaf/0.1/name', with: 'My Website'
    fill_in 'http://schema.org/description', with: 'About my website'
    fill_in 'https://argu.co/ns/core#shortname', with: 'my_website'
    check 'I accept the terms of use'
    click_button 'Save'

    wait(30).for(page).to have_current_path('/my_website/settings')
    expect(navbar).to have_content 'My Website'
    click_application_menu_button('My Argu websites')
    wait_for(page).to have_content 'About my website'
  end
end