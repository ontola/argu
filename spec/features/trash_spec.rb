# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trash', type: :feature do
  let(:title) { 'Title' }
  let(:content) { 'Content of discussion' }

  example 'trashed motion with explanation' do
    as 'staff@example.com', location: '/argu/m/38'

    go_to_menu_item('Delete')

    wait_for(page).to have_content 'This item will no longer be visible in public discussion. This can be undone.'

    fill_in field_name('https://argu.co/ns/core#trashActivity', 0, 'http://schema.org/text'), with: 'Trash reason', fill_options: {clear: :backspace}

    wait_for(page).to have_button('Trash')
    click_button 'Trash'

    wait_for(page).to have_snackbar "Idea trashed successfully"
    expect(page).to have_current_path('/argu/m/38')
    wait_for(page).to have_content 'This resource has been deleted'
    wait_for(page).to have_content 'Trash reason'
  end

  example 'trashed motion without explanation' do
    as 'staff@example.com', location: '/argu/m/38'

    go_to_menu_item('Delete')

    wait_for(page).to have_content 'This item will no longer be visible in public discussion. This can be undone.'

    wait_for(page).to have_button('Trash')
    click_button 'Trash'

    wait_for(page).to have_snackbar "Idea trashed successfully"
    expect(page).to have_current_path('/argu/m/38')
    wait_for(page).to have_content 'This resource has been deleted'
  end
end
