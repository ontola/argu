# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Navigations', type: :feature do
  example 'walk from page to argument' do
    as :guest, location: '/argu'

    go_to_child 'Freetown_question-title'
    go_to_child 'Question_motion-title'
    go_to_child 'Motion_argument-title'
    wait_for { page }.to have_content 'argument_comment-text'
    wait_for { page }.to have_content 'nested_argument_comment-text'
  end

  example 'walk from argument to forum' do
    as :guest, location: '/argu/pros/motion_argument'

    wait_for { page }.to have_content 'argument_comment-text'
    wait_for { page }.to have_content 'nested_argument_comment-text'
    go_to_parent 'Question_motion-title'
    go_to_parent 'Freetown_question-title'
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
