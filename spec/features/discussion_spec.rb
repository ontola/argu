# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Discussions', type: :feature do
  let(:title) { 'Title' }
  let(:content) { 'Content of discussion' }

  example 'Hide new discussion link when not allowed' do
    self.current_tenant = 'https://argu.localtest/other_page'
    as 'member@example.com', location: '/other_page'
    within '.NavBarContent__items' do
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
    expect(page).to have_current_path('/argu/freetown/q/new')
    wait_for { page }.to have_button 'Save'
    select_cover_photo
    select_attachment
    click_button 'Save'
    expect_draft_message('Challenge')
    expect_content('q/71', creator: 'User 61', images: false)
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
    expect_content('q/71', creator: 'first_name_3 last_name_3', images: false)
  end

  example 'Member posts a question' do
    as 'member@example.com', location: '/argu/holland/q/new'
    expect_form('/argu/holland/q')
    fill_in_form
    expect_draft_message('Challenge')
    expect_content('q/71')
  end

  example 'Member posts a motion' do
    as 'member@example.com', location: '/argu/holland/m/new'
    expect_form('/argu/holland/m')
    fill_in_form
    expect_draft_message('Idea')
    expect_content('m/71')
  end

  example 'Member posts a motion with required setup' do
    rails_runner(
      :argu,
      'Apartment::Tenant.switch(\'argu\') do'\
      '  Shortname.where(owner_type: \'User\').destroy_all;'\
      '  User.update_all(first_name: nil);'\
      '  Page.argu.update(requires_intro: true) '\
      'end'
    )
    as 'member@example.com', location: '/argu/holland/m/new'
    expect_form('/argu/holland/m')
    within navbar do
      expect(page).not_to have_link(href: '/argu/u/member')
    end
    fill_in_form(actor: 'last_name_26')
    wait_for { page }.to have_content 'Welcome!'
    within "[role='dialog']" do
      fill_in field_name('https://argu.co/ns/core#shortname'), with: 'member'
      fill_in field_name('http://schema.org/givenName'), with: 'username'
      click_button 'Save'
    end
    expect_draft_message('Idea')
    expect_content('m/71', creator: 'username last_name_26')

    within navbar do
      expect(page).to have_link(href: '/argu/u/member/profile')
      click_link(href: '/argu/u/member/profile')
    end

    within '.Page > .FullResource' do
      wait_for { page }.to have_content 'username last_name_26'
    end
  end

  example 'staff posts a question as page' do
    as 'staff@example.com', location: '/argu/holland/q/new'
    expect_form('/argu/holland/q', advanced: true)
    fill_in_form(actor: 'Argu page')
    expect_draft_message('Challenge')
    expect_content('q/71', creator: 'Argu page')
  end

  example 'staff updates a question' do
    as 'staff@example.com', location: '/argu/q/41'
    go_to_menu_item('Edit')
    expect_form('/argu/q/41', advanced: true)
    fill_in_form(actor: false)
    expect_updated_message('Challenge')
    expect_content('q/41', creator: 'first_name_32 last_name_32')
  end

  example 'staff updates a motion' do
    as 'staff@example.com', location: '/argu/m/38'
    go_to_menu_item('Edit')
    expect_form('/argu/m/38', advanced: true)
    fill_in_form(actor: false)
    expect_updated_message('Idea')
    expect_content('m/38', creator: 'first_name_30 last_name_30')
  end

  example 'staff updates a motion with movie attachment' do
    as 'staff@example.com', location: '/argu/m/38'
    go_to_menu_item('Edit')
    expect_form('/argu/m/38', advanced: true)
    click_button 'Attachments'
    within 'fieldset[property="https://argu.co/ns/core#attachments"]' do
      click_button 'On the internet'
      fill_in(
        field_name('https://argu.co/ns/core#attachments', 0, 'https://argu.co/ns/core#remoteContentUrl'),
        with: 'https://www.youtube.com/watch?v=mxQZNodm8OI'
      )
    end
    click_button 'Save'
    expect_updated_message('Idea')
    resource_selector('https://argu.localtest/argu/m/38/attachments', child: '.AttachmentPreview').click
    wait_for(page).to have_css('iframe[src="//www.youtube.com/embed/mxQZNodm8OI"]')
  end

  # @todo spec for showing inline errors [core#370]

  private

  def fill_in_form(actor: 'first_name_26 last_name_26')
    fill_in field_name('http://schema.org/name'), with: title, fill_options: {clear: :backspace}
    fill_in_markdown field_name('http://schema.org/text'), with: content
    click_button 'Cover photo'
    select_cover_photo
    click_button 'Attachments'
    select_attachment
    wait_until_loaded

    if actor
      fill_in_select(field_name('http://schema.org/creator'), with: actor)
    else
      expect(page).not_to have_content("div[aria-labelledby='#{field_name('http://schema.org/creator')}-label']")
    end
    click_button 'Save'
  end

  def expect_content(path, creator: 'first_name_26 last_name_26', images: true)
    wait_for { page }.to have_content(title)
    expect(page).to have_content(content)
    resource_selector("https://argu.localtest/argu/#{path}/attachments", child: '.AttachmentPreview') if images
    expect(page).to have_css('.CoverImage__wrapper') if images
    expect(page).to have_current_path("/argu/#{path}")
    expect(details_bar).to have_content(creator)
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
