# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Page settings', type: :feature do
  context 'general' do
    let(:tab) {}

    example 'as staff' do
      as 'staff@example.com'
      visit_settings
      fill_in_form
    end
  end

  context 'forums' do
    let(:tab) { 'Forums' }
    let(:new_email) { 'new_email@example.com' }
    let(:add_address_email) { mailcatcher_email(to: [new_email], subject: 'Add your e-mail address') }

    example 'as staff' do
      as 'staff@example.com'
      visit_settings
      wait_for(page).to have_content 'New Forum'
      expect(forums_row(1)).to have_content('Holland')
      expect(forums_row(2)).to have_content('Freetown')

      click_link('New forum')

      fill_in 'http://schema.org/name', with: 'New Forum'
      fill_in 'https://argu.co/ns/core#shortname', with: 'new_forum'
      click_button 'Save'

      wait_for(page).to have_content 'Forum created successfully'
      # @todo expect new forum in sidebar navigation

      visit_settings
      wait_for(page).to have_content 'New Forum'
      expect(forums_row(1)).to have_content('New Forum')
      expect(forums_row(2)).to have_content('Holland')
      expect(forums_row(3)).to have_content('Freetown')
      within(forums_row(1)) { find('td:last-child a').click }
      expect(page).to(
        have_content('This object and all related data will be permanently removed. This cannot be undone.')
      )
      fill_in 'https://argu.co/ns/core#confirmationString', with: 'remove'
      click_button 'Delete'
      wait_for(page).to have_content 'Forum deleted successfully'
      # @todo expect redirected to page settings
      # @todo expect new forum removed from sidebar navigation

      visit_settings
      # @todo expect(forums_row(1)).to have_content('Holland')
      # @todo expect(forums_row(2)).to have_content('Freetown')
    end
  end

  context 'groups' do
    let(:tab) { 'Groups' }

    example 'as staff' do
      as 'staff@example.com'
      visit_settings
      # @todo group management
    end
  end

  context 'advanced' do
    let(:tab) { 'Advanced' }

    example 'as staff' do
      as 'staff@example.com'
      visit_settings
      fill_in_form
    end
  end

  context 'redirects' do
    let(:tab) { 'Redirects' }

    example 'as staff' do
      as 'staff@example.com'
      visit_settings
      # @todo redirect management
    end
  end

  private

  def forums_row(row = 1)
    resource_selector(
      'https://app.argu.localtest/argu/forums?page=1&type=paginated',
      child: "tr:nth-child(#{row})"
    )
  end

  def fill_in_form(submit: 'Save')
    wait(30).for(page).to have_content submit
    # @todo fill in fields, press save check presence of new values and reload page to see if values are persisted.
  end

  def visit_settings
    within('.NavBarContent') do
      click_link 'Settings'
    end
    select_tab(tab) if tab
  end
end
