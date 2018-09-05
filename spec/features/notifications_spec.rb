# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Notifications', type: :feature do
  it 'marks notifications as read' do
    as 'user1@example.com'

    wait_for { sidebar }.to have_content 'Notifications (2)'
    click_link 'Notifications (2)'

    expect(page).to have_content 'first_name_30 last_name_30 posted a challenge in Freetown'
    expect(page).to have_content 'first_name_28 last_name_28 posted a idea in Freetown'

    expect(page.all('[data-test="Notification-Unread"]').count).to eq(2)
    page.all('[data-test="Notification-Unread"]').first.click
    wait_for { sidebar }.to have_content 'Notifications (1)'

    expect(page.all('[data-test="Notification-Unread"]').count).to eq(1)
  end
end
