# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Drafts', type: :feature do
  example 'User shows drafts' do
    as 'user55@example.com', location: '/argu/freetown/q/new'
    expect_form('/argu/freetown/q')
    fill_in field_name('http://schema.org/name'), with: 'Draft title'
    fill_in_markdown field_name('http://schema.org/text'), with: 'Draft content'
    click_button 'Save'
    wait_for { page }.to have_content('Draft version, not yet published.')

    go_to_user_page(tab: 'My drafts', user: 'user_name_57')

    wait_for { page }.to have_css('.CID-Heading', text: 'My drafts')
    wait_for { page }.to have_content 'Unpublished_question-title'
    wait_for { page }.to have_content 'Draft title'

    drafts = resource_selector('https://argu.localtest/argu/u/58/settings#drafts')
    draft_count = drafts.locator('.CID-Card').count
    expect(draft_count).to eq 2

    click_link 'Unpublished_question-title'
    wait_for { page }.to have_content 'Unpublished_motion-title'
    wait_for { page }.to have_content 'Fg argument title 7end'
    expect_publish_action
  end

  example 'Publish draft through action' do
    as 'user55@example.com', location: '/argu/q/unpublished_question'
    expect_publish_action
    within 'form[action="/argu/q/unpublished_question"]' do
      click_button 'Publish'
    end
    expect_published_message('Challenge')
    wait_for { page }.to have_content 'Unpublished_question-title'
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
