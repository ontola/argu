# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Drafts', type: :feature do
  example 'Show new discussion link as guest' do
    as 'user48@example.com', location: '/u/fg_shortname54end/drafts'

    wait_for(page).to have_content 'My drafts'
    wait_for(page).to have_content 'Fg question title 10end'
    expect(page).to have_css('.Card', count: 1)
    click_link 'Fg question title 10end'
    wait_for(page).to have_content 'Fg motion title 12end'
    wait_for(page).to have_content 'Fg argument title 8end'
    expect_publish_action
  end

  example 'Member posts a draft' do
    as 'member@example.com', location: '/argu/holland/discussions/new#new_question'
    expect_form('New challenge')
    fill_in 'http://schema.org/name', with: 'title', fill_options: {clear: :backspace}
    fill_in 'http://schema.org/text', with: 'content', fill_options: {clear: :backspace}
    select_draft_toggle
    click_button 'Save'
    expect(page).not_to have_content "It can take a few moments before it's visible on other pages."
    expect_publish_action
  end

  example 'Publish draft through action' do
    as 'user48@example.com', location: '/argu/q/56'
    expect_publish_action
    within 'div[resource="https://app.argu.localtest/argu/q/56/actions/publish#entrypoint"]' do
      click_button 'Publish'
    end
    expect_published_message('Challenge')
    expect_no_publish_action
  end

  private

  def expect_publish_action
    wait_for(page).to have_content 'Draft version, not yet published.'
    expect(page).not_to have_content 'Save as draft'
  end

  def expect_no_draft_toggle
    wait_until_loaded
    expect(page).not_to have_button 'Publish'
  end

  def expect_no_publish_action
    wait_until_loaded
    expect(page).not_to have_content 'Draft version, not yet published.'
    expect(page).not_to have_button 'Publish'
  end

  def select_draft_toggle
    expect(page).to have_content 'Save as draft'
    check 'Save as draft'
  end
end
