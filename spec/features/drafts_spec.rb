# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Drafts', type: :feature do
  example 'Show new discussion link as guest' do
    as 'user48@example.com', location: '/u/fg_shortname54end/drafts'

    wait_for(page).to have_content 'My drafts'
    wait_for(page).to have_content 'Fg question title 10end'
    expect(page).to have_css('.Card', count: 1)
  end
end
