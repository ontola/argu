# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Follow', type: :feature do
  example 'Follow motion' do
    as 'user1@example.com', location: '/argu/m/freetown_motion'

    change_follow('Important items') do
      expect_following 2
    end
    wait_for { page }.to have_snackbar 'Your notification settings are updated'
    change_follow('Important items') do
      expect_following 0
    end

    visit '/argu/m/freetown_motion'
    change_follow('Never receive notifications') do
      expect_following 0
    end
    wait_for { page }.to have_snackbar 'Your notification settings are updated'
    change_follow('Never receive notifications') do
      expect_following 2
    end
  end

  example 'Unfollow from notification' do
    expect(mailcatcher_email).to be_nil
    rails_runner(
      :argu,
      'Apartment::Tenant.switch(\'argu\') do '\
        'ActsAsTenant.with_tenant(Page.find_via_shortname(\'argu\')) do '\
          'User.find(3).update(notifications_viewed_at: 1.year.ago) '\
        'end '\
      'end'
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
    expect(notifications_email.body).to have_content 'New replies are posted in Freetown'

    unsubscribe_link = notifications_email.links.detect { |link| link.include?('follows') }
    visit unsubscribe_link
    wait_for { page }.to have_content "You are receiving notifications for all replies to 'Freetown'."
    wait_for { page }.to have_button 'Stop following'
    click_button 'Stop following'

    wait_for { page }.to have_snackbar "You no longer receive notifications for 'Freetown'."
    wait_for { page }.to have_current_path('/argu/freetown')

    verify_not_following(unsubscribe_link)
  end

  example 'Unfollow through POST' do
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
    expect(notifications_email.body).to have_content 'New replies are posted in Freetown'

    unsubscribe_link = notifications_email.links.detect { |link| link.include?('follows') }
    post_request = Faraday.new(unsubscribe_link, ssl: {verify: false}).post
    expect(post_request.status).to(eq(200))

    verify_not_following(unsubscribe_link)
  end

  private

  def change_follow(text)
    wait_for { page }.to have_css('a[title="Notifications"]')
    find('a[title="Notifications"]').click
    wait_until_loaded
    yield
    wait_for { page }.to have_css('.MuiListItemText-primary', text: text)
    sleep(1)
    find('.MuiListItemText-primary', text: text, match: :prefer_exact).click
  end

  def notifications_email
    @notifications_email ||= mailcatcher_email(to: ['user1@example.com'], subject: "New notifications in 'Freetown'")
  end

  def expect_following(index)
    Capybara.current_session.driver.with_playwright_page do |page|
      3.times do |i| button = page.locator("[role='menuitem']:nth-child(#{i + 2}) .fa-circle#{i == index ? '' : '-o'}")
        expect(button.visible?).to be_truthy
      end
    end
  end

  def verify_not_following(unsubscribe_link)
    visit unsubscribe_link
    wait_for { page }.to have_content "You are not receiving notifications for 'Freetown'."
    wait_until_loaded
    expect(page).not_to have_button 'Stop following'
  end
end
