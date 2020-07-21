# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Drafts', type: :feature do
  example 'Guest changes language' do
    as :guest
    click_application_menu_button('Set language')
    wait_for(page).to have_content('English')
    fill_in_select(field_name('http://schema.org/language'), with: 'Nederlands')
    click_button('Save')
    wait_for(page).to have_content('Taal instellen')
  end
end
