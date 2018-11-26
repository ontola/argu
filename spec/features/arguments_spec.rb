# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Arguments', type: :feature do
  let(:actor) { :guest }
  let(:go_to_parent) {}
  let(:location) { '/argu/m/32' }
  let(:title) { 'Title of argument' }
  let(:content) { 'Content of argument' }
  let(:after_post) do
    expect_argument_posted
  end

  shared_examples_for 'post argument' do
    before do
      as actor, location: location
    end

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
  end

  context 'as invitee' do
    let(:location) { '/tokens/valid_email_token' }
    let(:go_to_parent) do
      wait_for(page).to have_content('Fg motion title 3end')
      click_link 'Fg motion title 3end'
    end
    let(:after_post) do
      accept_terms
      # @todo post body when accepting terms
      # expect_argument_posted
    end
    it_behaves_like 'post argument'
  end

  private

  def fill_in_omniform(omniform_parent, click_to_open: false, side: 'pro')
    @side = side
    wait_until_loaded
    scope =
      resource_selector(
        page.current_url,
        element: omniform_parent
      )

    within scope do
      click_button 'Share your response...' if click_to_open
      click_button "Argument #{@side == 'pro' ? 'in favour' : 'against'}"
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
    wait_for(page).to have_content "#{@side.capitalize} created successfully"
    within resource_selector("#{page.current_url}/#{@side}s", element: '.Column > div') do
      wait_for(page).to have_content title
      wait_for(page).to have_content content
    end
  end
end
