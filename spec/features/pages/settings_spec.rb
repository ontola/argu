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

  context 'components' do
    let(:tab) { 'Components' }
    let(:new_email) { 'new_email@example.com' }

    example 'as staff' do
      as 'staff@example.com'
      visit_settings
      wait_for(page).to have_content 'Container nodes'
      expect(components_row(1)).to have_content('Holland')
      expect(components_row(2)).to have_content('Freetown')

      click_application_menu_button('New forum')

      wait_for(page).to have_css('.Page form')
      fill_in 'http://schema.org/name', with: 'New Forum'
      fill_in 'https://argu.co/ns/core#shortname', with: 'new_forum'
      fill_in_select 'https://argu.co/ns/core#publicGrant', with: 'Participate'
      click_button 'Save'

      wait_for(page).to have_snackbar 'Forum created successfully'
      # @todo expect new forum in topbar navigation

      # @todo fetch /container_nodes instead of /forums after posting a forum, so the reload can be removed
      visit '/argu/settings#container_nodes'
      # visit_settings

      wait_until_loaded
      wait_for(page).to have_content 'Container nodes'
      expect(components_row(1)).to have_content('New Forum')
      expect(components_row(2)).to have_content('Holland')
      expect(components_row(3)).to have_content('Freetown')
      within(components_row(1)) do
        wait_for(page).to have_css('.fa-close')
        find('td:last-child a').click
      end
      expect(page).to(
        have_content('This object and all related data will be permanently removed. This cannot be undone.')
      )
      fill_in 'https://argu.co/ns/core#confirmationString', with: 'remove'
      click_button 'Delete'
      wait_for(page).to have_snackbar 'Forum deleted successfully'
      # @todo expect redirected to page settings
      # @todo expect new forum removed from sidebar navigation

      visit_settings
      # @todo expect(components_row(1)).to have_content('Holland')
      # @todo expect(components_row(2)).to have_content('Freetown')
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

  def add_address_email
    @add_address_email ||= mailcatcher_email(to: [new_email], subject: 'Add your e-mail address')
  end

  def components_row(row = 1)
    resource_selector(
      'https://app.argu.localtest/argu/container_nodes?display=settingsTable&page=1',
      child: "tbody tr:nth-child(#{row})"
    )
  end

  def fill_in_form(submit: 'Save')
    wait(30).for(page).to have_content submit
    # @todo fill in fields, press save check presence of new values and reload page to see if values are persisted.
  end

  def visit_settings
    wait_for(page).to have_content('Settings')
    within('.NavBarContent') do
      click_link 'Settings'
    end
    select_tab(tab) if tab
  end
end
