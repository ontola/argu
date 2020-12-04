# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Disabled actions', type: :feature do
  let(:state_expectation) { nil }

  shared_examples_for 'cannot perform actions' do
    before do
      as :guest, location: location
    end

    example 'visit item' do
      wait_until_loaded
      state_expectation

      wait_for { page }.not_to have_button('Share a response...')
      expect(page).not_to have_css('.Omniform')
      expect(page).not_to have_css('.Omniform__preview')
      expect(page).not_to have_css('.fa-plus')
      vote_buttons_expectation
    end
  end

  context 'trashed question' do
    let(:location) { '/argu/q/58' }
    let(:state_expectation) { expect(page).to have_content('This resource has been deleted on') }
    let(:vote_buttons_expectation) { expect(page).not_to have_css('.Button') }

    it_behaves_like 'cannot perform actions'
  end

  context 'expired question' do
    let(:location) { '/argu/q/66' }
    let(:state_expectation) { expect(page).to have_css('.fa-lock') }
    let(:vote_buttons_expectation) do
      expect(page).to have_css('.Button[disabled][title="Voting no longer possible"]', count: 3)
    end

    it_behaves_like 'cannot perform actions'
  end

  context 'motion of trashed question' do
    let(:location) { '/argu/m/59' }
    let(:vote_buttons_expectation) { expect(page).not_to have_css('.Button') }

    it_behaves_like 'cannot perform actions'
  end

  context 'motion of expired question' do
    let(:location) { '/argu/m/67' }
    let(:vote_buttons_expectation) do
      expect(page).to have_css('.Button[disabled][title="Voting no longer possible"]', count: 4)
    end

    it_behaves_like 'cannot perform actions'
  end
end
