# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Drafts', type: :feature do
  example 'User shows drafts' do
    as 'user48@example.com', location: '/argu/u/fg_shortname54end/drafts'

    wait_for { page }.to have_content 'My drafts'
    wait_for { page }.to have_content 'Fg question title 10end'
    expect(page).to have_css('.Card', count: 1)
    click_link 'Fg question title 10end'
    wait_for { page }.to have_content 'Fg motion title 12end'
    wait_for { page }.to have_content 'Fg argument title 8end'
    expect_publish_action
  end

  example 'Publish draft through action' do
    as 'user48@example.com', location: '/argu/q/62'
    expect_publish_action
    within 'div[resource="https://argu.localtest/argu/q/62/actions/publish#EntryPoint"]' do
      click_button 'Publish'
    end
    expect_published_message('Challenge')
    wait_for { page }.to have_content 'Fg question title 10end'
    expect_no_publish_action
  end

  private

  def expect_publish_action
    wait_for { page }.to have_content 'Draft version, not yet published.'
    expect(page).not_to have_content 'Save as draft'
  end

  def expect_no_draft_toggle
    wait_until_loaded
    expect(page).not_to have_button 'Publish'
  end

  def expect_no_publish_action
    wait_until_loaded
    wait_for { page }.not_to have_content 'Draft version, not yet published.'
    expect(page).not_to have_button 'Publish'
  end

  def select_draft_toggle
    expect(page).to have_content 'Save as draft'
    check 'Save as draft'
  end
end
