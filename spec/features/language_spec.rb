# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Language', type: :feature do
  example 'Guest changes language' do
    as :guest
    click_application_menu_button('Set language')
    wait_for(page).to have_css('input[value="English"]')
    fill_in_select(field_name('http://schema.org/language'), with: 'Nederlands')
    click_button('Save')
    wait_for(page).to have_content('Taal instellen')
    wait_for(page).to have_css('input[value="Nederlands"]')
  end
end
