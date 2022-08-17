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
      components_row(1).locator('text=Holland')
      components_row(2).locator('text=Freetown')

      playwright_page.locator('h2', hasText: 'Components').click

      collection_float_button('Add item').click

      within_dialog do
        wait_for { page }.to have_content('Forum')
        click_link 'Forum'
      end

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

      wait_for { page }.to have_snackbar 'Forum created successfully'
      navbar.locator('text=New Forum')
      wait_until_loaded
      components_row(1).locator('text=New Forum')
      components_row(2).locator('text=Holland')
      components_row(3).locator('text=Freetown')
      first_row = components_row(1)
      first_row.locator('.fa-close')
      first_row.locator('td:last-child a').click

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
      components_row(1).locator('text=Holland')
      components_row(2).locator('text=Freetown')
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
      shortnames_row(1).locator('text=No items yet')

      wait_until_loaded
      playwright_page.locator('h2', hasText: 'Redirects').click

      collection_float_button('New redirect').click
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
    wait_for { page }.to have_content submit
    # @todo fill in fields, press save check presence of new values and reload page to see if values are persisted.
  end

  def shortnames_row(row = 1)
    resource_selector(
      'https://argu.localtest/argu/shortnames',
      child: "tbody tr:nth-child(#{row})",
      element: '.CID-Card'
    )
  end

  def visit_settings
    playwright_page.locator('text=Manage').click
    select_tab(tab) if tab
  end
end
