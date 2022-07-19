# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Not found', type: :feature do
  example 'request non-cached non authorized resource' do
    as(:guest, location: '/argu/q/hidden_question')
    wait_for { page }.to have_content('This item is hidden')
    wait_for { page }.to have_link('Log in')
    wait_for { page }.not_to have_content('Hidden_question-title')
  end

  example 'request cached non authorized resource' do
    as('staff@example.com', location: '/argu/q/hidden_question')
    wait_for { page }.to have_content('Hidden_question-title')
    wait_for { page }.not_to have_content('This item is hidden')
    wait_for { page }.not_to have_link('Log in')
    logout(user: 'argu_owner')
    wait_for { page }.to have_content('This item is hidden')
    wait_for { page }.to have_link('Log in')
    wait_for { page }.not_to have_content('Hidden_question-title')
  end
end
