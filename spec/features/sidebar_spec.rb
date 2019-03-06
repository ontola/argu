# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sidebar', type: :feature do
  it 'show default organization on homepage' do
    as :guest, location: '/'

    expect(navbar).to have_content 'Argu page'
  end

  it 'has organization color' do
    as :guest, location: '/argu'

    expect(navbar[:style]).to match(/background-color: rgb\(71, 86, 104\)/)

    expect(navbar).not_to have_content 'Other page'

    switch_organization 'other_page'

    wait_for { navbar[:style] }.to match(/background-color: rgb\(128, 0, 0\)/)
  end

  it 'shows one forum for guest, two for staff' do
    as :guest, location: '/argu'

    expect(navbar_tabs).to have_content 'Freetown'
    expect(navbar_tabs).not_to have_content 'Holland'

    login('staff@example.com')

    expect(navbar_tabs).to have_content 'Freetown'
    expect(navbar_tabs).to have_content 'Holland'
  end
end
