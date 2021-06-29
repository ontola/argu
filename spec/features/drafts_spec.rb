# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Drafts', type: :feature do
  example 'User shows drafts' do
    as 'user55@example.com', location: '/argu/freetown/q/new'
    expect_form('/argu/freetown/q')
    fill_in field_name('http://schema.org/name'), with: 'Draft title'
    fill_in_markdown field_name('http://schema.org/text'), with: 'Draft content'
    click_button 'Save'
    wait_for(page).to have_content('Draft version, not yet published.')

    go_to_user_page('My drafts')

    wait_for { page }.to have_css('.Heading', text: 'My drafts')
    wait_for { page }.to have_content 'Fg question title 10end'
    wait_for { page }.to have_content 'Draft title'
    within(resource_selector('https://argu.localtest/argu/u/58/profile#drafts')) do
      expect(page).to have_css('.Card', count: 2)
    end
    click_link 'Fg question title 10end'
    wait_for { page }.to have_content 'Fg motion title 13end'
    wait_for { page }.to have_content 'Fg argument title 8end'
    expect_publish_action
  end

  example 'Publish draft through action' do
    as 'user55@example.com', location: '/argu/q/62'
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
