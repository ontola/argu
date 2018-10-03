# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User profile', type: :feature do
  it 'shows the profile of a user' do
    as(:guest, location: '/u/fg_shortname35end')
    wait_for(page).to have_content('first_name_32 last_name_32')
    wait_for(page).to have_content('Fg question title 7end')
  end
end
