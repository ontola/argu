# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Logout', type: :feature do
  it 'authenticates a valid user' do
    as('user1@example.com')
    expect(current_user_section).to be_truthy
    logout
    wait_until_loaded
    wait_for { page }.not_to have_css 'div[resource="https://app.argu.localtest/c_a"]'
  end
end
