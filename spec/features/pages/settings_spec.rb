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
      wait_for { page }.to have_content 'Components'
      wait_for(components_row(1)).to have_content('Holland')
      wait_for(components_row(2)).to have_content('Freetown')

      resource_selector(
        'https://argu.localtest/argu/container_nodes?display=settingsTable',
        element: '.ContainerFloat',
        child: '.fa-plus'
      ).click

      wait_for { page }.to have_content('New forum')
      click_link 'New forum'

      wait_for { page }.to have_css('.Page form')
      fill_in field_name('http://schema.org/name'), with: 'New Forum'
      fill_in field_name('https://argu.co/ns/core#shortname'), with: 'new_forum'
      wait_until_loaded
      click_button 'Grants'
      wait_until_loaded
      fill_in_select(
        field_name('https://argu.co/ns/core#grants', 0, 'https://argu.co/ns/core#group'),
        with: 'Public'
      )
      fill_in_select(
        field_name('https://argu.co/ns/core#grants', 0, 'https://argu.co/ns/core#grantSet'),
        with: 'Participate'
      )
      click_button 'Save'

      wait_for { page }.to have_snackbar 'Forum created successfully'
      # @todo expect new forum in topbar navigation

      # @todo fetch /container_nodes instead of /forums after posting a forum, so the reload can be removed
      visit '/argu/settings#container_nodes'
      # visit_settings

      wait_until_loaded
      wait_for { page }.to have_content 'Components'
      expect(components_row(1)).to have_content('New Forum')
      expect(components_row(2)).to have_content('Holland')
      expect(components_row(3)).to have_content('Freetown')
      within(components_row(1)) do
        wait(30).for(page).to have_css('.fa-close')
        find('td:last-child a').click
      end
      expect(page).to(
        have_content('This object and all related data will be permanently removed. This cannot be undone.')
      )
      fill_in field_name('https://argu.co/ns/core#confirmationString'), with: 'remove'
      click_button 'Delete'
      wait_for { page }.to have_snackbar 'Forum deleted successfully'
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

  context 'redirects' do
    let(:tab) { 'Redirects' }

    example 'as staff' do
      as 'staff@example.com'
      visit_settings
      # @todo redirect management
    end
  end

  private

  def components_row(row = 1)
    resource_selector(
      'https://argu.localtest/argu/container_nodes?display=settingsTable',
      child: "tbody tr:nth-child(#{row})",
      element: '.Card'
    )
  end

  def fill_in_form(submit: 'Save')
    wait(30).for(page).to have_content submit
    # @todo fill in fields, press save check presence of new values and reload page to see if values are persisted.
  end

  def visit_settings
    wait_for { page }.to have_content('Settings')
    within('.NavBarContent') do
      click_link 'Settings'
    end
    select_tab(tab) if tab
  end
end
