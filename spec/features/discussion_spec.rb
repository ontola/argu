# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Discussions', type: :feature do
  let(:title) { 'Title' }
  let(:content) { 'Content of discussion' }

  example 'Show new discussion link as guest' do
    as :guest, location: '/argu/freetown'

    wait_for(page).to have_content 'New Idea'
    click_link 'New idea'
    # @todo AOD-407
    # wait_for(page).to have_content 'You have to be logged in to view this resource.'
  end

  example 'Hide new discussion link when not allowed' do
    self.current_tenant = 'https://app.argu.localtest/other_page'
    as 'member@example.com', location: '/other_page'
    within '.PrimaryResource' do
      wait_for(page).to have_content 'Other page forum'
      click_link 'Other page forum'
    end

    expect(page).not_to have_content 'New Idea'
    expect(page).not_to have_content 'New Challenge'

    switch_organization 'argu'
    wait_for(page).to have_content 'Freetown', count: 2
    within '.PrimaryResource' do
      click_link 'Freetown'
    end
    expect(page).to have_content 'New Idea'
    expect(page).to have_content 'New Challenge'
  end

  example 'Member posts a question' do
    as 'member@example.com', location: '/argu/holland/q/new'
    expect_form('/argu/holland/q')
    fill_in_form
    expect_published_message('Challenge')
    expect_content('q/68')
  end

  example 'Member posts a motion' do
    as 'member@example.com', location: '/argu/holland/m/new'
    expect_form('/argu/holland/m')
    fill_in_form
    expect_published_message('Idea')
    expect_content('m/68')
  end

  example 'staff updates a question' do
    as 'staff@example.com', location: '/argu/q/39'
    go_to_menu_item('Edit')
    expect_form('/argu/q/39')
    fill_in_form
    expect_updated_message('Challenge')
    expect_content('q/39')
  end

  example 'staff updates a motion' do
    as 'staff@example.com', location: '/argu/m/36'
    go_to_menu_item('Edit')
    expect_form('/argu/m/36')
    fill_in_form
    expect_updated_message('Idea')
    expect_content('m/36')
  end

  private

  def fill_in_form
    fill_in 'http://schema.org/name', with: title, fill_options: {clear: :backspace}
    fill_in 'http://schema.org/text', with: content, fill_options: {clear: :backspace}
    within 'div[property="https://argu.co/ns/core#coverPhoto"]' do
      attach_file 'Content', File.absolute_path('spec/fixtures/cover_photo.jpg')
    end
    within 'div[property="https://argu.co/ns/core#attachments"]' do
      attach_file 'Content', File.absolute_path('spec/fixtures/profile_photo.png')
    end
    click_button 'Save'
  end

  def expect_content(path)
    wait_for(page).to have_content(title)
    expect(page).to have_content(content)
    resource_selector("https://app.argu.localtest/argu/#{path}/attachments", child: '.AttachmentPreview')
    expect(page).to have_css('.CoverImage__wrapper')
    expect(current_path).to include("/argu/#{path}")
  end
end
