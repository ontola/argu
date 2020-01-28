# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Decisions', type: :feature do
  example 'Staff approves motion' do
    as 'staff@example.com', location: '/argu/m/38'
    go_to_menu_item('Take decision')
    wait_for(page).to have_content 'Take a decision'
    select_radio 'Approve'
    fill_in_markdown(
      'http://schema.org/text',
      with: 'Reason for decision',
    )
    click_button 'Save'
    wait_for(page).to have_snackbar 'Idea is approved'
    within('#start-of-content') do
      wait_for(page).to have_content 'Idea is approved'
    end
    expect(page).to(have_content('Reason for decision'))
  end

  example 'Staff rejects motion' do
    as 'staff@example.com', location: '/argu/m/38'
    go_to_menu_item('Take decision')
    wait_for(page).to have_content 'Take a decision'
    select_radio 'Reject'
    fill_in_markdown(
      'http://schema.org/text',
      with: 'Reason for decision',
    )
    click_button 'Save'
    wait_for(page).to have_snackbar 'Idea is rejected'
    within('#start-of-content') do
      wait_for(page).to have_content 'Idea is rejected'
    end
    expect(page).to(have_content('Reason for decision'))
  end
end
