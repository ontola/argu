# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Collection', type: :feature do
  example 'Guest shows infinite activities feed' do
    as :guest, location: '/argu/feed'
    wait_for(page).to have_content('Activities')
    wait_until_loaded
    wait_for { resource_selector(page.current_url) }.to have_css('.Card', count: 10)
    click_button('Load more')
    wait_until_loaded
    wait_for { resource_selector(page.current_url) }.to have_css('.Card', count: 19)
  end

  example 'Guest shows paginated activities feed' do
    as :guest, location: '/argu/feed?type=paginated'
    wait_for(page).to have_content('Activities')
    wait_until_loaded
    collection_iri = page.current_url
    wait_for { resource_selector(collection_iri) }.to have_css('.Card', count: 10)
    expect(page).not_to have_content('Load more')
    click_button '2'
    wait_until_loaded
    wait_for { resource_selector(collection_iri) }.to have_css('.Card', count: 9)
  end
end
