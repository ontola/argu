# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User settings', type: :feature do
  context 'general' do
    let(:tab) {}

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      fill_in_form
    end
  end

  context 'profile' do
    let(:tab) { 'Profile' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      fill_in_form
    end
  end

  context 'authentication' do
    let(:tab) { 'Authentication' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      fill_in_form
    end
  end

  context 'notifications' do
    let(:tab) { 'Notifications' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      fill_in_form
    end
  end

  context 'privacy' do
    let(:tab) { 'Privacy' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      fill_in_form
    end
  end

  context 'delete' do
    let(:tab) { 'Privacy' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      wait_for(page).to have_button 'Remove account'
      click_button 'Remove account'
      fill_in_form(submit: 'Delete')
    end
    # @todo Not allowed to delete as super admin
    # example 'as staff' do
    #   as 'user1@example.com'
    #   visit_settings
    # end
  end

  context 'email addresses' do
    let(:tab) { 'Authentication' }
    let(:new_email) { 'new_email@example.com' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      wait_for(page).to have_content 'Email addresses'
      expect_email_row(1, 'user1@example.com', true, true)
      resource_selector(
        'https://argu.localtest/argu/u/fg_shortname3end/email_addresses?display=settingsTable',
        element: '.ContainerFloat',
        child: '.fa-plus'
      ).click
      fill_in 'http://schema.org/email', with: new_email
      click_button 'Add'
      wait_for(page).to have_content 'Email addresses'
      expect_email_row(1, new_email, false, false)
      expect_email_row(2, 'user1@example.com', true, true)

      expect_email(:add_address_email)
      mailcatcher_clear

      click_button 'Send confirmation link again'
      expect_email(:confirmation_email)
      expect(page).not_to have_content('Make primary email address')

      visit confirmation_email.links.last
      visit_settings
      wait_for(page).to have_content 'Email addresses'
      expect_email_row(1, new_email, false, true)
      expect_email_row(2, 'user1@example.com', true, true)

      click_button 'Make primary email address'
      wait_for(page).to have_snackbar('Email address saved successfully')
      expect_email_row(1, new_email, true, true)
      expect_email_row(2, 'user1@example.com', false, true)
    end
  end

  private

  def add_address_email
    @add_address_email ||= mailcatcher_email(to: [new_email], subject: 'Add your e-mail address')
  end

  def confirmation_email
    @confirmation_email ||= mailcatcher_email(to: [new_email], subject: 'Confirm your e-mail address')
  end

  def email_addresses_row(row = 1)
    resource_selector(
      'https://argu.localtest/argu/u/fg_shortname3end/email_addresses?display=settingsTable',
      child: "tbody tr:nth-child(#{row})",
      element: '.Card'
    )
  end

  def expect_email_row(row, email, primary, confirmed)
    wait_for(page).to have_content(email)
    expect(email_addresses_row(row)).to have_content(email)
    expect(email_addresses_row(row)).send(primary ? :to : :not_to, have_content('Primary e-mail address'))
    expect(email_addresses_row(row)).send(confirmed ? :to : :not_to, have_content('Already confirmed'))
  end

  def fill_in_form(submit: 'Save')
    wait(30).for(page).to have_content submit
    # @todo fill in fields, press save and reload page to see if values are persisted.
  end

  def visit_settings
    click_application_menu_button 'User settings'
    select_tab(tab) if tab
  end
end
