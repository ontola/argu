# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Notifications', type: :feature do
  it 'marks notifications as read' do
    as 'user1@example.com'

    within navbar do
      wait_for { count_bubble_count }.to have_content '6'
    end

    go_to_user_page('Notifications')

    expect(page).to have_content 'first_name_32 last_name_32 posted a challenge in Freetown'
    expect(page).to have_content 'first_name_30 last_name_30 posted a idea in Freetown'
    expect(page).to have_content 'first_name_57 last_name_57 posted a thread in Freetown'

    wait_until_loaded

    wait_for { page.all('[data-test="Notification-Unread"]').count }.to eq(6)
    page.all('[data-test="Notification-Unread"]').first.click
    within navbar do
      wait_for { count_bubble_count }.to have_content '5'
    end

    expect(page.all('[data-test="Notification-Unread"]').count).to eq(5)
  end
end
