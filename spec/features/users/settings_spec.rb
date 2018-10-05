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
    let(:tab) { 'Delete' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      fill_in_form(submit: 'Delete')
    end

    # @todo Not allowed to delete as super admin
    # example 'as staff' do
    #   as 'user1@example.com'
    #   visit_settings
    # end
  end

  context 'email addresses' do
    let(:tab) { 'Emails' }

    example 'as user' do
      as 'user1@example.com'
      visit_settings
      wait_for(page).to have_content 'Email addresses'
      # @todo expect(page).to have_content 'user1@example.com'
      # @todo confirm/remove/add email addresses
    end
  end

  private

  def visit_settings
    expect(current_user_section).to be_truthy
    current_user_section('.SideBarCollapsible__toggle').click
    wait_for { current_user_section }.to have_content 'User settings'
    current_user_section(:link, 'User settings').click
    select_tab(tab)
  end

  def select_tab(tab)
    return unless tab

    wait_for(page).to have_css('.TabBar')
    within '.TabBar' do
      click_link tab
    end
  end

  def fill_in_form(submit: 'Save')
    wait(30).for(page).to have_content submit
    # @todo fill in fields, press save and reload page to see if values are persisted.
  end
end
