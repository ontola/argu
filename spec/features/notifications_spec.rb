# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Notifications', type: :feature do
  it 'marks notifications as read' do
    as 'user1@example.com'

    within sidebar do
      wait_for { count_bubble_count }.to have_content '2'
    end
    click_link 'Notifications'

    expect(page).to have_content 'first_name_31 last_name_31 posted a challenge in Freetown'
    expect(page).to have_content 'first_name_29 last_name_29 posted a idea in Freetown'

    expect(page.all('[data-test="Notification-Unread"]').count).to eq(2)
    page.all('[data-test="Notification-Unread"]').first.click
    wait_for { sidebar }.to have_content 'Notifications'
    within sidebar do
      wait_for { count_bubble_count }.to have_content '1'
    end

    expect(page.all('[data-test="Notification-Unread"]').count).to eq(1)
  end
end
