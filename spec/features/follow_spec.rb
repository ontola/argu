# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Follow', type: :feature do
  example 'Follow motion' do
    as 'user1@example.com', location: '/argu/m/32'

    resource_selector("#{page.current_url}/menus/follow").click
    expect_following 2
    find('span', text: 'Important items').click
    wait_for(page).to have_content 'Your notification settings are updated'
    expect_following 0

    visit '/argu/m/32'
    resource_selector("#{page.current_url}/menus/follow").click
    expect_following 0
    find('span', text: 'Never receive notifications').click
    wait_for(page).to have_content 'Your notification settings are updated'
    expect_following 2
  end

  example 'Unfollow from notification' do
    expect(mailcatcher_email).to be_nil
    rails_runner(
      :argu,
      'User.find(3).update(notifications_viewed_at: 1.day.ago); '\
      'SendActivityNotificationsWorker.new.perform(3, User.reactions_emails[:direct_reactions_email])'
    )
    expect_email(:notifications_email)
    expect(notifications_email.body).to have_content 'New replies are posted in Freetown.'

    unsubscribe_link = notifications_email.links.detect { |link| link.include?('unsubscribe') }
    visit unsubscribe_link
    wait_for(page).to have_content "You no longer receive notifications for 'Freetown'"
    expect(current_path).to eq('/argu/freetown')

    visit unsubscribe_link
    wait_for(page).to have_content "You don't receive notifications already for 'Freetown'"
    expect(current_path).to eq('/argu/freetown')
  end

  private

  def notifications_email
    @notifications_email ||= mailcatcher_email(to: ['user1@example.com'], subject: "New notifications in 'Freetown'")
  end

  def expect_following(index)
    3.times do |i|
      expect(page).to(
        have_css(".Dropdown__content .DropdownLink:nth-child(#{i + 1}) .fa-circle#{i == index ? '' : '-o'}")
      )
    end
  end
end
