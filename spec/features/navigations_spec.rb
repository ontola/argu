# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Navigations', type: :feature do
  example 'walk from page to argument' do
    as :guest, location: '/o'

    go_to_child 'Argu page'
    go_to_child 'Freetown'
    go_to_child 'Fg question title 7end'
    go_to_child 'Fg motion title 9end'
    go_to_child 'Fg argument title 6end'
    expect(page).to have_content 'fg comment body 2end'
  end

  example 'walk from argument to forum' do
    as :guest, location: '/argu/pro/41'

    expect(page).to have_content 'fg comment body 2end'
    go_to_parent 'Fg motion title 9end'
    go_to_parent 'Fg question title 7end'
    go_to_parent 'Freetown'
    expect(page).to have_content 'Discussions'
  end

  private

  def go_to_child(name)
    wait_for(page).to have_content(name)
    within '.MainContentWrapper' do
      click_link name
    end
  end

  def go_to_parent(name)
    wait_for(page).to have_content(name)
    within('.PrimaryResource') do
      click_link name
    end
  end
end