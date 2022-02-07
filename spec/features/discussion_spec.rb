# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Discussions', type: :feature do
  let(:title) { 'Title' }
  let(:content) { 'Content of discussion' }

  example 'Hide new discussion link when not allowed' do
    self.current_tenant = 'https://argu.localtest/other_page'
    as 'member@example.com', location: '/other_page'
    within '.CID-NavBarContentItems' do
      wait_for { page }.to have_content 'Other page forum'
      click_link 'Other page forum'
    end

    wait_until_loaded
    wait_for { page }.not_to have_content 'New idea'
    expect(page).not_to have_content 'New challenge'

    switch_organization 'argu'
    wait_for { page }.to have_content 'Freetown'
    wait_for { page }.to have_content 'New idea'
    expect(page).to have_content 'New challenge'
  end

  example 'Guest posts a question as new user' do
    as :guest, location: '/argu/freetown/q/new'
    expect_form('/argu/freetown/q')
    fill_in_form(actor: false)
    fill_in_registration_form
    verify_logged_in
    finish_setup
    expect(page).to have_current_path('/argu/freetown/q/new')
    wait_for { page }.to have_button 'Save'
    select_cover_photo
    select_attachment
    click_button 'Save'
    expect_draft_message('Challenge')
    expect_content("q/#{next_id}", creator: 'New user', images: false)
  end

  example 'Guest posts a question as existing user' do
    as :guest, location: '/argu/freetown/q/new'
    expect_form('/argu/freetown/q')
    fill_in_form(actor: false)
    login('user1@example.com', open_modal: false)
    expect(page).to have_current_path('/argu/freetown/q/new')
    wait_for { page }.to have_button 'Save'
    select_cover_photo
    select_attachment
    click_button 'Save'
    expect_draft_message('Challenge')
    expect_content("q/#{next_id}", creator: 'user_name_2', images: false)
  end

  example 'Member posts a question' do
    as 'member@example.com', location: '/argu/holland/q/new'
    expect_form('/argu/holland/q')
    fill_in_form
    expect_draft_message('Challenge')
    expect_content("q/#{next_id}")
  end

  example 'Member posts a motion' do
    as 'member@example.com', location: '/argu/holland/m/new'
    expect_form('/argu/holland/m')
    fill_in_form
    expect_draft_message('Idea')
    expect_content("m/#{next_id}")
  end

  example 'Member posts a motion from omniform' do
    as 'member@example.com', location: '/argu/q/freetown_question'
    wait_for { page }.to have_content('Share your idea...')
    click_button 'Share your idea...'

    expect_form('/argu/q/freetown_question/m')
    wait_until_loaded
    fill_in_form(submit: 'Publish', omniform: true)
    expect_published_message('Idea')
    wait_for { page }.to have_content(title)
    expect(page).to have_content(content)
  end

  example 'Member posts a motion with required setup' do
    rails_runner(
      :argu,
      'Apartment::Tenant.switch(\'argu\') do'\
      '  User.update_all(display_name: nil, finished_intro: false);'\
      '  Page.argu.update(requires_intro: true) '\
      'end'
    )
    as 'member@example.com', location: '/argu/holland/m/new'
    cancel_setup
    expect_form('/argu/holland/m')
    fill_in_form(actor: 'User 27')
    wait_for { page }.to have_content 'Welcome!'
    finish_setup
    expect_draft_message('Idea')
    expect_content("m/#{next_id}", creator: 'New user')

    click_user_menu_button('Profile')

    within 'main' do
      wait_for { page }.to have_content 'New user'
    end
  end

  example 'staff posts a question as page' do
    as 'staff@example.com', location: '/argu/holland/q/new'
    expect_form('/argu/holland/q', advanced: true)
    fill_in_form(actor: 'Argu page')
    expect_draft_message('Challenge')
    expect_content("q/#{next_id}", creator: 'Argu page')
  end

  example 'staff updates a question' do
    as 'staff@example.com', location: '/argu/q/freetown_question'
    select_tab('Edit')
    expect_form('/argu/q/freetown_question', advanced: true)
    fill_in_form(actor: false)
    expect_updated_message('Challenge')
    expect_content('q/freetown_question', creator: 'user_name_36')
  end

  example 'staff updates a motion' do
    as 'staff@example.com', location: '/argu/m/freetown_motion'
    select_tab('Edit')
    expect_form('/argu/m/freetown_motion', advanced: true)
    fill_in_form(actor: false)
    expect_updated_message('Idea')
    expect_content('m/freetown_motion', creator: 'user_name_34')
  end

  example 'staff updates a motion with movie attachment' do
    as 'staff@example.com', location: '/argu/m/freetown_motion'
    select_tab('Edit')
    expect_form('/argu/m/freetown_motion', advanced: true)
    add_child_to_form('Attachments')
    within 'fieldset[property="https://argu.co/ns/core#attachments"]' do
      click_button 'On the internet'
      fill_in(
        field_name('https://argu.co/ns/core#attachments', 0, 'https://argu.co/ns/core#remoteContentUrl'),
        with: 'https://www.youtube.com/watch?v=mxQZNodm8OI'
      )
    end
    click_button 'Save'
    expect_updated_message('Idea')
    wait_for { page }.to have_css(test_selector('ImageAttachmentPreview'))
    find(test_selector('ImageAttachmentPreview')).click
    wait_for { page }.to have_css('iframe[src="//www.youtube.com/embed/mxQZNodm8OI"]')
  end

  # @todo spec for showing inline errors [core#370]

  private

  def fill_in_form(actor: 'user_name_26', submit: 'Save', omniform: false)
    fill_in field_name('http://schema.org/name'), with: title, fill_options: {clear: :backspace}
    fill_in_markdown field_name('http://schema.org/text'), with: content
    if omniform
      click_button 'Cover photo'
    else
      add_child_to_form('Cover photo')
    end
    select_cover_photo
    if omniform
      click_button 'Attachments'
    else
      add_child_to_form('Attachments')
    end
    select_attachment
    wait_until_loaded

    if actor
      fill_in_select(field_name('http://schema.org/creator'), with: actor)
    else
      expect(page).not_to have_content("div[aria-labelledby='#{field_name('http://schema.org/creator')}-label']")
    end
    click_button submit
  end

  def expect_content(path, creator: 'user_name_26', images: true)
    wait_for { page }.to have_content(title)
    expect(page).to have_content(content)
    wait_for { page }.to have_css(test_selector('ImageAttachmentPreview')) if images
    expect(page).to have_css(test_id_selector('CoverPhoto')) if images
    expect(page).to have_current_path("/argu/#{path}")
    details_bar.locator("text=#{creator}")
  end

  def select_attachment
    within 'fieldset[property="https://argu.co/ns/core#attachments"]' do
      click_button 'On my computer'
      attach_file(nil, File.absolute_path('spec/fixtures/profile_photo.png'), make_visible: true)
    end
  end

  def select_cover_photo
    within('fieldset[property="https://ns.ontola.io/core#coverPhoto"]') do
      attach_file(nil, File.absolute_path('spec/fixtures/cover_photo.jpg'), make_visible: true)
    end
  end
end
