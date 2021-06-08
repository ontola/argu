# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Navigations', type: :feature do
  example 'walk from page to argument' do
    as :guest, location: '/argu'

    go_to_child 'Fg question title 7end'
    go_to_child 'Fg motion title 10end'
    go_to_child 'Fg argument title 6end'
    wait_for { page }.to have_content 'fg comment body 2end'
  end

  example 'walk from argument to forum' do
    as :guest, location: '/argu/pros/47'

    wait_for { page }.to have_content 'fg comment body 2end'
    go_to_parent 'Fg motion title 10end'
    go_to_parent 'Fg question title 7end'
    go_to_parent 'Freetown'
    wait_for { page }.to have_content 'Do you have a good idea?'
  end

  private

  def go_to_child(name)
    wait_for { page }.to have_content(name)
    within '.Page' do
      wait_for { page }.to have_content(name)
      click_link name
    end
  end

  def go_to_parent(name)
    wait_for { page }.to have_content(name)
    within('.Page') do
      click_link name
    end
  end
end
