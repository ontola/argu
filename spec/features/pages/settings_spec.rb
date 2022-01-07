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
      wait_for { components_row(1) }.to have_content('Holland')
      wait_for { components_row(2) }.to have_content('Freetown')

      find('h2', text: 'Components').click

      resource_selector(
        'https://argu.localtest/argu/container_nodes?display=settingsTable',
        element: '.CID-ContainerFloat',
        child: '.fa-plus'
      ).click

      wait_for { page }.to have_content('New forum')
      click_link 'New forum'

      within_dialog do
        wait_for { page }.to have_css('form')
        fill_in field_name('http://schema.org/name'), with: 'New Forum'
        fill_in field_name('https://argu.co/ns/core#shortname'), with: 'new_forum'
        wait_until_loaded
        add_child_to_form('Grants')
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
      end

      wait_for { page }.to have_snackbar 'Forum created successfully'
      within navbar do
        wait_for { page }.to have_content 'New Forum'
      end

      wait_until_loaded
      wait_for { page }.to have_content 'Components'
      wait_until_loaded
      expect(components_row(1)).to have_content('New Forum')
      expect(components_row(2)).to have_content('Holland')
      expect(components_row(3)).to have_content('Freetown')
      within(components_row(1)) do
        wait(30).for(page).to have_css('.fa-close')
        find('td:last-child a').click
      end
      within_dialog do
        expect(page).to(
          have_content('This object and all related data will be permanently removed. This cannot be undone.')
        )
        fill_in field_name('https://argu.co/ns/core#confirmationString'), with: 'remove'
        click_button 'Delete'
      end
      expect_no_dialog
      # @todo fix stale element error for window.logging
      # wait_for { page }.to have_snackbar 'Forum deleted successfully'

      wait_for {page}.not_to have_content('New Forum')
      expect(components_row(1)).to have_content('Holland')
      expect(components_row(2)).to have_content('Freetown')
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
      wait_for { page }.to have_content 'Redirects'
      wait_for { shortnames_row(1) }.to have_content('No items yet')

      find('h2', text: 'Redirects').click

      resource_selector(
        'https://argu.localtest/argu/shortnames?display=settingsTable',
        element: '.CID-ContainerFloat',
        child: '.fa-plus'
      ).click
      wait_for { page }.to have_content('New redirect')
      fill_in field_name('https://argu.co/ns/core#shortname'), with: 'question66'
      fill_in field_name('https://argu.co/ns/core#destination'), with: 'https://argu.localtest/argu/q/expired_question'
      click_button('Save')
      wait_for { page }.to have_content('Expired_question-title')
      visit 'https://argu.localtest/argu/question66'
      wait_for { page }.to have_current_path('/argu/q/expired_question')
      wait_for { page }.to have_content('Expired_question-title')
    end
  end

  private

  def components_row(row = 1)
    resource_selector(
      'https://argu.localtest/argu/container_nodes?display=settingsTable',
      child: "tbody tr:nth-child(#{row})",
      element: '.CID-Card'
    )
  end

  def fill_in_form(submit: 'Save')
    wait(30).for(page).to have_content submit
    # @todo fill in fields, press save check presence of new values and reload page to see if values are persisted.
  end

  def shortnames_row(row = 1)
    resource_selector(
      'https://argu.localtest/argu/shortnames?display=settingsTable',
      child: "tbody tr:nth-child(#{row})",
      element: '.CID-Card'
    )
  end

  def visit_settings
    wait_for { page }.to have_content('Settings')
    within('.CID-NavBarContentItems') do
      click_link 'Settings'
    end
    select_tab(tab) if tab
  end
end
