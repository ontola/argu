# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Follow', type: :feature do
  example 'Follow motion' do
    as 'user1@example.com', location: '/argu/m/38'

    go_to_menu_item('Important items', menu: :follow) do
      expect_following 2
    end
    wait_for(page).to have_snackbar 'Your notification settings are updated'
    expect_following 0

    visit '/argu/m/38'
    go_to_menu_item('Never receive notifications', menu: :follow) do
      expect_following 0
    end
    wait_for(page).to have_snackbar 'Your notification settings are updated'
    expect_following 2
  end

  example 'Unfollow from notification' do
    expect(mailcatcher_email).to be_nil
    rails_runner(
      :argu,
      'Apartment::Tenant.switch(\'argu\') { User.find(3).update(notifications_viewed_at: 1.year.ago) }'
    )
    rails_runner(
      :argu,
      'Apartment::Tenant.switch(\'argu\') do '\
        'ActsAsTenant.with_tenant(Page.find_via_shortname(\'argu\')) do '\
          'SendActivityNotificationsWorker.new.perform(3, User.reactions_emails[:direct_reactions_email]) '\
        'end '\
      'end'
    )

    expect_email(:notifications_email)
    expect(notifications_email.body).to have_content 'New replies are posted in Freetown.'

    unsubscribe_link = notifications_email.links.detect { |link| link.include?('unsubscribe') }
    visit unsubscribe_link
    wait_for(page).to have_snackbar "You no longer receive notifications for 'Freetown'."
    expect(page).to have_current_path('/argu/freetown')

    visit unsubscribe_link
    wait_for(page).to have_snackbar "You don't receive notifications already for 'Freetown'."
    wait_for(page).to have_current_path('/argu/freetown')
  end

  private

  def notifications_email
    @notifications_email ||= mailcatcher_email(to: ['user1@example.com'], subject: "New notifications in 'Freetown'")
  end

  def expect_following(index)
    3.times do |i|
      expect(page).to(
        have_css(".Dropdown__content .DropdownLink:nth-child(#{i + 2}) .fa-circle#{i == index ? '' : '-o'}")
      )
    end
  end
end
