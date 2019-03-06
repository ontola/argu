# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Notifications', type: :feature do
  it 'marks notifications as read' do
    as 'user1@example.com'

    within navbar do
      wait_for { count_bubble_count }.to have_content '4'
    end
    # @todo add link to notification in UI
    # click_link 'Notifications'
    visit 'https://app.argu.localtest/argu/n'

    expect(page).to have_content 'first_name_32 last_name_32 posted a challenge in Freetown'
    expect(page).to have_content 'first_name_30 last_name_30 posted a idea in Freetown'

    expect(page.all('[data-test="Notification-Unread"]').count).to eq(4)
    page.all('[data-test="Notification-Unread"]').first.click
    within navbar do
      wait_for { count_bubble_count }.to have_content '3'
    end

    expect(page.all('[data-test="Notification-Unread"]').count).to eq(3)
  end
end
