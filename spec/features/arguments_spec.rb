# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Arguments', type: :feature do
  let(:location) { '/argu/m/32' }
  let(:title) { 'Title of argument' }
  let(:content) { 'Content of argument' }

  def fill_in_omniform(omniform_parent, click_to_open: false, side: 'pro')
    scope =
      resource_selector(
        "https://app.argu.localtest#{location}",
        element: omniform_parent
      )

    within scope do
      click_button 'Plaats jouw reactie...' if click_to_open
      click_button "Argument #{side == 'pro' ? 'in favour' : 'against'}"
      wait_for(page).to have_field 'http://schema.org/name'
      fill_in 'http://schema.org/name', with: title
      fill_in 'http://schema.org/text', with: content
      click_button 'Opslaan'
    end
    wait_for(page).to have_content "#{side.capitalize} created successfully"
    within resource_selector("https://app.argu.localtest#{location}/#{side}s", element: '.Column > div') do
      wait_for(page).to have_content title
      wait_for(page).to have_content content
    end
  end

  shared_examples_for 'post argument' do
    before do
      as actor, location: location
    end

    example 'pro from card section' do
      parent = '.PrimaryResource div:nth-child(1) div.Card'
      fill_in_omniform(parent, click_to_open: true)
    end

    example 'pro from motion footer' do
      parent = '.PrimaryResource div:nth-child(3) div.Card'
      fill_in_omniform(parent)
    end

    example 'con from motion footer' do
      parent = '.PrimaryResource div:nth-child(3) div.Card'
      fill_in_omniform(parent, side: 'con')
    end
  end

  context 'As guest' do
    let(:actor) { :guest }
    # @todo login flow in omniform
    # it_behaves_like 'post argument'
  end

  context 'As user' do
    let(:actor) { 'user1@example.com' }
    it_behaves_like 'post argument'
  end
end
