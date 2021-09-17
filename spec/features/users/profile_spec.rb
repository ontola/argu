# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User profile', type: :feature do
  it 'shows the profile of a user' do
    as(:guest, location: '/argu/u/37')
    wait_for { page }.to have_content('user_name_36')
    wait_for { page }.to have_content('Freetown_question-title')
    visit '/other_page/u/37'
    wait_for { page }.to have_content('No items yet')
  end
end
