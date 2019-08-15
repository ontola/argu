# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Arguments', type: :feature do
  let(:actor) { :guest }
  let(:go_to_parent) {}
  let(:location) { '/argu/m/38' }
  let(:title) { 'Title of argument' }
  let(:content) { 'Content of argument' }
  let(:after_post) do
    expect_argument_posted
  end
  let(:result_element) { '.Column > div' }
  let(:parent_resource) { page.current_url }
  let(:expect_argument_content) { true }

  before do
    as actor, location: location
  end

  shared_examples_for 'post argument' do
    example 'pro from card section' do
      parent = '.PrimaryResource div:nth-child(1) div.Card'
      go_to_parent
      fill_in_omniform(parent, click_to_open: true)
    end

    example 'pro from motion footer' do
      parent = '.PrimaryResource div:nth-child(3) div.Card'
      go_to_parent
      fill_in_omniform(parent)
    end

    example 'con from motion footer' do
      parent = '.PrimaryResource div:nth-child(3) div.Card'
      go_to_parent
      fill_in_omniform(parent, side: 'con')
    end
  end

  context 'As guest' do
    # @todo login flow in omniform
    # it_behaves_like 'post argument'
  end

  context 'As user' do
    let(:actor) { 'user1@example.com' }
    it_behaves_like 'post argument'

    context 'question#show' do
      let(:location) { '/argu/q/41' }
      let(:result_element) { '.Column .CardList' }
      let(:parent_resource) { 'https://app.argu.localtest/argu/m/42' }
      let(:expect_argument_content) { false }

      example 'pro from motion preview' do
        parent = ".Card[resource=\"#{parent_resource}\"]"

        fill_in_omniform(parent, click_to_open: true)
      end
    end
  end

  context 'as invitee' do
    let(:location) { '/argu/tokens/valid_email_token' }
    let(:go_to_parent) do
      accept_token
      wait(30).for(page).to have_content('Fg motion title 3end')
      click_link 'Fg motion title 3end'
    end
    let(:after_post) do
      accept_terms
      expect_argument_posted
    end
    it_behaves_like 'post argument'
  end

  private

  def fill_in_omniform(omniform_parent, click_to_open: false, side: 'pro')
    @side = side
    wait_for(page).to have_content 'Comment'
    wait_for(page).to have_content 'Pro' unless click_to_open
    wait_for(page).to have_content 'Con' unless click_to_open
    wait_until_loaded
    scope =
      resource_selector(
        parent_resource,
        element: omniform_parent
      )

    wait_for(page).to have_content('Share your response...')
    within scope do
      click_button 'Share your response...' if click_to_open
      click_button @side.capitalize
      wait_for(page).to have_field 'http://schema.org/name'
      fill_in 'http://schema.org/name', with: title
      fill_in 'http://schema.org/text', with: content
      within '.Form__footer--right' do
        find('.Button--submit').click
      end
    end

    after_post
  end

  def expect_argument_posted
    wait_for(page).to(
      have_snackbar(
        "#{@side.capitalize} published successfully. It can take a few moments before it's visible on other pages."
      )
    )
    wait_until_loaded
    wait_for(page).to have_content title
    within resource_selector("#{parent_resource}/#{@side}s", element: result_element) do
      wait_for(page).to have_content title
      wait_for(page).to have_content content if expect_argument_content
    end
  end
end
