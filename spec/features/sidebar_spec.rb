# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sidebar', type: :feature do
  it 'show default organization on homepage' do
    as :guest, location: '/'

    expect(sidebar).to have_content 'Argu page'
  end

  it 'switches organization by switcher' do
    as :guest, location: '/argu'

    expect(sidebar[:style]).to match(/background-color: rgb\(71, 86, 104\)/)

    expect(sidebar).not_to have_content 'Other page'

    switch_organization 'Other page'

    wait_for(sidebar[:style]).to match(/background-color: rgb\(128, 0, 0\)/)

    switch_organization 'Argu page'

    wait_for(sidebar[:style]).to match(/background-color: rgb\(71, 86, 104\)/)
  end

  it 'shows one forum for guest, two for staff' do
    as :guest, location: '/argu'

    expect(sidebar_top.find('.MenuSectionLabel')).to have_content 'FORUM'
    expect(sidebar_top).not_to have_content 'Freetown'
    expect(sidebar_top).not_to have_content 'Holland'

    login('staff@example.com')

    expect(sidebar_top('.MenuSectionLabel')).to have_content 'FORUMS'
    expect(sidebar_top).to have_content 'Freetown'
    expect(sidebar_top).to have_content 'Holland'
  end
end
