# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Notifications', type: :feature do
  it 'marks notifications as read' do
    as 'user1@example.com'

    count_bubble_count.locator("text=5")
    count_bubble_count.click

    wait_for { page }.to have_content 'user_name_36 posted a challenge in Freetown'
    expect(page).to have_content 'user_name_34 posted a idea in Freetown'
    expect(page).to have_content 'user_name_63 posted a thread in Freetown'

    wait_until_loaded

    Capybara.current_session.driver.with_playwright_page do |page|
      wait_for { page.locator(test_selector('Notification-Unread')).count }.to eq 5
      page.locator(test_selector('Notification-Unread')).first.click

      count_bubble_count.locator("text=4")

      wait_for { page.locator(test_selector('Notification-Unread')).count }.to eq 4
      expect(page.locator(test_selector('Notification-Unread')).count).to eq 4
    end
  end
end
