# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Delete', type: :feature do
  let(:title) { 'Title' }
  let(:content) { 'Content of discussion' }

  example 'Delete motion' do
    as 'staff@example.com', location: '/argu/m/freetown_motion'

    go_to_menu_item('Delete permanently')

    wait_for { page }.to have_content 'This object and all related data will be permanently removed. This cannot be undone.'

    wait_for { page }.to have_button('Delete')
    click_button 'Delete'

    wait_for { page }.to have_snackbar "Idea deleted successfully"

    playwright_page.expect_navigation do
      visit '/argu/freetown'
    end

    wait_for { page }.to have_content 'Freetown_question-title'
    wait_for { page }.not_to have_content 'Freetown_motion-title'
  end
end
