# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Token email management legacy', type: :feature do
  before do
    use_legacy_frontend
  end

  scenario 'Owner adds and retracts email token' do
    as('staff@example.com', location: '/argu/g/111/settings?tab=invite')

    wait_for(page).to have_content('Pending invites')
    expect(page).not_to have_css('.email-token-management .is-loading')
    wait_for(page).to have_css '.email-token-management table tbody tr', count: 3

    within('.select-users-and-emails') do
      fill_in_select with: 'first_name_5 last_name_5'
    end

    click_button('Send invites')

    expect_email(:invite_email)

    expect(invite_email.body).to include("I invite you to join the group 'Members'.")

    wait_for(page).to have_css '.email-token-management table tbody tr', count: 4
  end

  private

  def invite_email
    @invite_email ||= mailcatcher_email(to: ['user3@example.com'], subject: 'Uitnodiging voor Argu page op Argu')
  end
end
