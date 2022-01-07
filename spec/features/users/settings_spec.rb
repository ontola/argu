# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User settings', type: :feature do
  let(:form_group) { nil }

  context 'profile' do
    let(:tab) { 'Profile' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      fill_in_form
    end
  end

  context 'authentication' do
    let(:tab) { 'Settings' }
    let(:form_group) { 'Authentication' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      fill_in_form
    end
  end

  context 'notifications' do
    let(:tab) { 'Settings' }
    let(:form_group) { 'Notifications' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
    end
  end

  context 'privacy' do
    let(:tab) { 'Settings' }
    let(:form_group) { 'Privacy' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      fill_in_form
    end
  end

  context 'delete' do
    let(:tab) { 'Settings' }
    let(:form_group) { 'Privacy' }

    example 'as user' do
      as 'user23@example.com'
      visit_settings
      wait_for { page }.to have_link 'Remove account'
      click_link 'Remove account'
      fill_in_form(submit: 'Delete')
      # @todo What happens after remove?
    end
    # @todo Not allowed to delete as super admin
    # example 'as staff' do
    #   as 'user1@example.com'
    #   visit_settings
    # end
  end

  context 'email addresses' do
    let(:tab) { 'Settings' }
    let(:form_group) { 'Email addresses' }
    let(:new_email) { 'new_email@example.com' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      expect_email_row(1, 'user1@example.com', true, true)
      wait_until_loaded
      find('h2', text: 'Email addresses').click
      resource_selector(
        'https://argu.localtest/argu/email_addresses?display=settingsTable',
        element: '.CID-ContainerFloat',
        child: '.fa-plus'
      ).click
      fill_in field_name('http://schema.org/email'), with: new_email
      click_button 'Add'
      wait_for { page }.to have_content form_group
      wait_until_loaded
      expand_form_group form_group
      expect_email_row(1, new_email, false, false)
      expect_email_row(2, 'user1@example.com', true, true)

      expect_email(:add_address_email)
      mailcatcher_clear

      find('a .fa-send').click
      expect_email(:confirmation_email)
      expect(page).to have_css('button:disabled .fa-circle-o')

      visit confirmation_email.links.last
      visit_settings
      wait_for { page }.to have_content 'Email addresses'
      expect_email_row(1, new_email, false, true)
      expect_email_row(2, 'user1@example.com', true, true)

      find('a .fa-circle-o').click
      wait_for { page }.to have_snackbar('Email address saved successfully')
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
      'https://argu.localtest/argu/email_addresses?display=settingsTable',
      child: "tbody tr:nth-child(#{row})",
      element: '.CID-Card'
    )
  end

  def expect_email_row(row, email, primary, confirmed)
    wait_for { page }.to have_content(email)
    expect(email_addresses_row(row)).to have_content(email)
    if primary
      expect(email_addresses_row(row)).to have_css('button:disabled .fa-circle')
    elsif confirmed
      expect(email_addresses_row(row)).to have_css('a .fa-circle-o')
    else
      expect(email_addresses_row(row)).to have_css('button:disabled .fa-circle-o')
    end

    expect(email_addresses_row(row)).to have_css("#{confirmed ? 'button:disabled' : 'a'} .fa-send")
  end

  def fill_in_form(submit: 'Save')
    wait(30).for(page).to have_content submit
    # @todo fill in fields, press save and reload page to see if values are persisted.
  end

  def visit_settings
    go_to_user_page(tab)

    return unless form_group

    wait_for { page }.to have_content form_group
    expand_form_group form_group
  end
end
