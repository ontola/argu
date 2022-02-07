# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Navbar', type: :feature do
  it 'show freetown on homepage' do
    redis_cache_persisted_client.set(
      'cache:redirect:argu.localtest',
      'https://argu.localtest/argu'
    )
    as :guest, location: '/'

    wait_for { page }.to have_content 'Freetown'
  end

  it 'has organization color' do
    as :guest, location: '/argu'

    expect(css_var('--navbar-background')).to eq('#475668')
    expect(css_var('--accent-color')).to eq('#FFFFFF')

    expect(navbar).not_to have_content 'Other page'

    switch_organization 'other_page'

    wait_for { css_var('--navbar-background') }.to eq('#800000')
    expect(css_var('--accent-color')).to eq('#FFFFFF')
  end

  it 'shows no forum for guest, one for staff' do
    as :guest, location: '/argu'

    wait_for { navbar_tabs.locator('text=Freetown').count }.to be 0
    wait_for { navbar_tabs.locator('text=Holland').count }.to be 0

    login('staff@example.com')

    wait_for { navbar_tabs.locator('text=Freetown').count }.to be 0
    wait_for { navbar_tabs.locator('text=Holland').count }.to be 1
  end

  private

  def css_var(var)
    page.driver.evaluate_script("getComputedStyle(document.documentElement).getPropertyValue('#{var}')")
  end
end
