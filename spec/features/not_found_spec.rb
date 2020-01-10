# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Not found', type: :feature do
  example 'request non existing tenant' do
    as(:guest, location: '/wrong_tenant')
    expect(page).to have_content('Not Found')
  end

  example 'request non existing path' do
    as(:guest, location: '/argu/wrong_tenant')
    wait_for(page).to have_content('This item is not found')
    wait_for(page).to have_button('Try again')
  end
end