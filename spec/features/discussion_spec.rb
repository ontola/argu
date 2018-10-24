# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Discussions', type: :feature do
  let(:title) { 'Title' }
  let(:content) { 'Content of discussion' }

  example 'Show new discussion link as guest' do
    as :guest, location: '/argu'

    wait_for(page).to have_content 'New discussion'
    click_link 'New discussion'
    wait_for(page).to have_content 'Niet ingelogd'
  end

  example 'Hide new discussion link when not allowed' do
    as 'member@example.com', location: '/other_page'
    expect_discussion_button('other_page', 'Other page forum', false)
    expect_discussion_button('other_page', 'Other page forum2', false)

    switch_organization 'Argu'
    expect_discussion_button('argu', 'Freetown', true)
    expect_discussion_button('argu', 'Holland', true)

    click_link 'New discussion'
    expect_form('New challenge')
    click_link 'New motion'
    expect_form('New idea')
  end

  example 'Member posts a question' do
    as 'member@example.com', location: '/argu/holland/discussions/new#new_question'
    expect_form('New challenge')
    fill_in_form
    expect_published_message('Challenge')
    expect_content('q/64')
  end

  example 'Member posts a motion' do
    as 'member@example.com', location: '/argu/holland/discussions/new#new_motion'
    expect_form('New idea')
    fill_in_form
    expect_published_message('Idea')
    expect_content('m/64')
  end

  example 'staff updates a question' do
    as 'staff@example.com', location: '/argu/q/35'
    go_to_menu_item('Edit')
    expect_form('Update')
    fill_in_form
    expect_updated_message('Challenge')
    expect_content('q/35')
  end

  example 'staff updates a motion' do
    as 'staff@example.com', location: '/argu/m/32'
    go_to_menu_item('Edit')
    expect_form('Update')
    fill_in_form
    expect_updated_message('Idea')
    expect_content('m/32')
  end

  private

  def expect_discussion_button(organization, forum, expect)
    wait_for(page).to have_content forum
    resource_selector(
      "https://app.argu.localtest/#{organization}/menus/navigations#forums.#{forum.downcase.tr(' ', '_')}",
      parent: sidebar,
      child: '.SideBarCollapsible__toggle'
    ).click
    expectation = have_content('New discussion')
    expect ? expect(sidebar).to(expectation) : expect(sidebar).not_to(expectation)
  end

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
