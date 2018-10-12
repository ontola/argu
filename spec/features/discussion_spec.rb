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
    expect_new_content('Challenge', 'q')
  end

  example 'Member posts a motion' do
    as 'member@example.com', location: '/argu/holland/discussions/new#new_motion'
    expect_form('New idea')
    fill_in_form
    expect_new_content('Idea', 'm')
  end

  private

  def expect_discussion_button(organization, forum, expect) # rubocop:disable Metrics/AbcSize:
    wait_for(page).to have_content forum
    resource_selector(
      "https://app.argu.localtest/#{organization}/menus/navigations#forums.#{forum.downcase.tr(' ', '_')}",
      parent: sidebar,
      child: '.SideBarCollapsible__toggle'
    ).click
    expectation = have_content('New discussion')
    expect ? expect(sidebar).to(expectation) : expect(sidebar).not_to(expectation)
  end

  def expect_form(name)
    wait_for(page).to have_content name
    expect(page).to have_css 'form'
  end

  def fill_in_form
    fill_in 'http://schema.org/name', with: title
    fill_in 'http://schema.org/text', with: content
    attach_file 'Content', File.absolute_path('spec/fixtures/profile_photo.png')
    # @todo upload cover_photo
    click_button 'Save'
  end

  def expect_new_content(type, path) # rubocop:disable Metrics/AbcSize:
    wait_for(page).to(
      have_content("#{type} created successfully. it can take a few moments before it's visible on other pages")
    )
    wait_for(page).to have_content(title)
    expect(page).to have_content(content)
    resource_selector("https://app.argu.localtest/argu/#{path}/64/attachments", child: '.AttachmentPreview')
    # @todo expect cover_photo
    expect(current_path).to include("/argu/#{path}/")
  end
end
