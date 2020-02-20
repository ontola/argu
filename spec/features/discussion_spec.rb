# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Discussions', type: :feature do
  let(:title) { 'Title' }
  let(:content) { 'Content of discussion' }

  example 'Hide new discussion link when not allowed' do
    self.current_tenant = 'https://argu.localtest/other_page'
    as 'member@example.com', location: '/other_page'
    within '.NavBarContent' do
      wait_for { page }.to have_content 'Other page forum'
      click_link 'Other page forum'
    end

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
    fill_in_form
    fill_in_registration_form
    verify_logged_in
    expect(page).to have_current_path('/argu/freetown/q/new')
    wait_for { page }.to have_button 'Save'
    click_button 'Save'
    expect_draft_message('Challenge')
    expect_content('q/71', images: false)
  end

  example 'Guest posts a question as existing user' do
    as :guest, location: '/argu/freetown/q/new'
    expect_form('/argu/freetown/q')
    fill_in_form
    login('user1@example.com', open_modal: false)
    expect(page).to have_current_path('/argu/freetown/q/new')
    wait_for { page }.to have_button 'Save'
    click_button 'Save'
    expect_draft_message('Challenge')
    expect_content('q/71', images: false)
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
      '  Page.argu.update(requires_intro: true) '\
      'end'
    )
    as 'member@example.com', location: '/argu/holland/m/new'
    expect_form('/argu/holland/m')
    within navbar do
      expect(page).not_to have_link(href: '/argu/u/member')
    end
    fill_in_form
    wait_for { page }.to have_content 'Welcome!'
    within "[role='dialog']" do
      click_button 'Save'
    end
    expect_draft_message('Idea')
    expect_content('m/71')

    within navbar do
      expect(page).to have_link(href: '/argu/u/member')
      click_link(href: '/argu/u/member')
    end

    within '.Page > .FullResource' do
      wait_for { page }.to have_content 'first_name_26 last_name_26'
    end
  end

  example 'staff updates a question' do
    as 'staff@example.com', location: '/argu/q/41'
    go_to_menu_item('Edit')
    expect_form('/argu/q/41')
    fill_in_form
    expect_updated_message('Challenge')
    expect_content('q/41')
  end

  example 'staff updates a motion' do
    as 'staff@example.com', location: '/argu/m/38'
    go_to_menu_item('Edit')
    expect_form('/argu/m/38')
    fill_in_form
    expect_updated_message('Idea')
    expect_content('m/38')
  end

  private

  def fill_in_form
    fill_in 'http://schema.org/name', with: title, fill_options: {clear: :backspace}
    fill_in_markdown 'http://schema.org/text', with: content
    within('fieldset[property="https://ns.ontola.io/coverPhoto"]') do
      click_button 'Cover photo'
      attach_file(nil, File.absolute_path('spec/fixtures/cover_photo.jpg'), make_visible: true)
    end
    within 'fieldset[property="https://argu.co/ns/core#attachments"]' do
      click_button 'Attachments'
      attach_file(nil, File.absolute_path('spec/fixtures/profile_photo.png'), make_visible: true)
    end
    click_button 'Save'
  end

  def expect_content(path, images: true)
    wait_for { page }.to have_content(title)
    expect(page).to have_content(content)
    resource_selector("https://argu.localtest/argu/#{path}/attachments", child: '.AttachmentPreview') if images
    expect(page).to have_css('.CoverImage__wrapper') if images
    expect(page).to have_current_path("/argu/#{path}")
  end
end
