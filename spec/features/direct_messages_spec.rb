# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Direct messages', type: :feature do
  example 'Staff sends a direct message' do
    as 'staff@example.com', location: '/argu/m/38'
    go_to_menu_item('Contact poster')
    wait_for(page).to have_content 'Send an e-mail to first_name_30 last_name_30'
    fill_in_select 'http://schema.org/email', with: 'staff@example.com'
    fill_in 'http://schema.org/name', with: 'Example subject'
    fill_in 'http://schema.org/text', with: 'Example body'
    click_button 'Send'
    wait_for(page).to have_snackbar 'The mail will be sent'
    expect_email :direct_message_email
    expect(direct_message_email.body).to(
      have_content('first_name_1 last_name_1 has sent you a message in response to Fg motion title 8end.')
    )
  end

  private

  def direct_message_email
    @direct_message_email ||= mailcatcher_email(to: ['user27@example.com'], subject: 'Example subject')
  end
end
