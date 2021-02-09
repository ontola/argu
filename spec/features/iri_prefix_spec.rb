# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'iri prefix', type: :feature do
  example 'Question with other iri prefix' do
    as :guest, location: '/argu/q/41'
    wait_for(page).to have_content('Fg question title 7end')
    expect(page).to have_current_path('/argu/q/41')
    change_iri_prefix('demogemeente.localdev')
    click_link('Freetown')
    # @todo this should be fixed
    wait_for(page).to have_content('Internal server error')

    visit "https://argu.localtest/argu/q/41"
    wait_for(page).to have_content('Fg question title 7end')
    expect(page).to have_current_path('/q/41')

    visit "https://demogemeente.localdev/q/41"
    wait_for(page).to have_content('Fg question title 7end')
    expect(page).to have_current_path('/q/41')
  end

  private

  def change_iri_prefix(iri_prefix)
    rails_runner(
      :argu,
      'Apartment::Tenant.switch(\'argu\') do '\
        "Page.find_via_shortname(\'argu\').update(iri_prefix: '#{iri_prefix}') "\
      'end'
    )
  end
end
