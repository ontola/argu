# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Notifications', type: :feature do
  it 'marks notifications as read' do
    as 'user1@example.com'

    within navbar do
      wait_for { count_bubble_count }.to have_content '5'
    end

    go_to_user_page('Notifications')

    expect(page).to have_content 'user_name_37 posted a challenge in Freetown'
    expect(page).to have_content 'user_name_35 posted a idea in Freetown'
    expect(page).to have_content 'user_name_64 posted a thread in Freetown'

    wait_until_loaded

    wait_for { page.all(test_selector('Notification-Unread')).count }.to eq(5)
    page.all(test_selector('Notification-Unread')).first.click
    within navbar do
      wait_for { count_bubble_count }.to have_content '4'
    end

    expect(page.all(test_selector('Notification-Unread')).count).to eq(4)
  end
end
