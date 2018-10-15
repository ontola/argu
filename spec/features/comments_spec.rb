# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Comments', type: :feature do
  let(:location) { '/argu/m/32' }
  let(:content) { 'Content of comment' }

  def fill_in_omniform(omniform_parent, click_to_open: false) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    scope =
      resource_selector(
        "https://app.argu.localtest#{location}",
        element: omniform_parent
      )

    within scope do
      click_button 'Plaats jouw reactie...' if click_to_open
      fill_in 'http://schema.org/text', with: content
      click_button 'Opslaan'
    end
    wait_for(page).to have_content 'Comment created successfully'
    within resource_selector("https://app.argu.localtest#{location}/c", element: '.Container > div') do
      wait_for(page).to have_content content
    end
  end

  shared_examples_for 'post comment' do
    before do
      as actor, location: location
    end

    example 'from card section' do
      parent = '.PrimaryResource div:nth-child(1) div.Card'
      fill_in_omniform(parent, click_to_open: true)
    end

    example 'from motion footer' do
      parent = '.PrimaryResource div:nth-child(3) div.Card'
      fill_in_omniform(parent)
    end
  end

  context 'As guest' do
    let(:actor) { :guest }
    # @todo login flow in omniform
    # it_behaves_like 'post comment'
  end

  context 'As user' do
    let(:actor) { 'user1@example.com' }
    it_behaves_like 'post comment'
  end
end
