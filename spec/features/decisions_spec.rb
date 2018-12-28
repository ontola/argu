# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Decisions', type: :feature do
  example 'Staff approves motion' do
    as 'staff@example.com', location: '/argu/m/36'
    go_to_menu_item('Take decision')
    wait_for(page).to have_content 'Take a decision'
    fill_in_select 'https://argu.co/ns/core#decisionState', with: 'Approved'
    fill_in 'http://schema.org/text', with: 'Reason for decision'
    click_button 'Save'
    wait_for(page).to have_content 'Idea is approved', count: 2
    expect(page).to(have_content('Reason for decision'))
  end

  example 'Staff rejects motion' do
    as 'staff@example.com', location: '/argu/m/36'
    go_to_menu_item('Take decision')
    wait_for(page).to have_content 'Take a decision'
    fill_in_select 'https://argu.co/ns/core#decisionState', with: 'Rejected'
    fill_in 'http://schema.org/text', with: 'Reason for decision'
    click_button 'Save'
    wait_for(page).to have_content 'Idea is rejected', count: 2
    expect(page).to(have_content('Reason for decision'))
  end
end
