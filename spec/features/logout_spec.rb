# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Logout', type: :feature do
  it 'authenticates a valid user' do
    as('user1@example.com')
    logout
    wait_until_loaded
    verify_not_logged_in
  end
end
