# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'iri prefix', type: :feature do
  example 'Question with other iri prefix' do
    as :guest, location: '/argu/q/freetown_question'
    wait_for(page).to have_content('Freetown_question-title')
    expect(page).to have_current_path('/argu/q/freetown_question')
    change_iri_prefix('demogemeente.localdev')
    click_link('Freetown')
    # @todo this should be fixed
    wait_for(page).to have_content('Internal server error')

    visit 'https://argu.localtest/argu/q/freetown_question'
    wait_for(page).to have_content('Freetown_question-title')
    expect(page).to have_current_path('/q/freetown_question')

    visit 'https://demogemeente.localdev/q/freetown_question'
    wait_for(page).to have_content('Freetown_question-title')
    expect(page).to have_current_path('/q/freetown_question')
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
