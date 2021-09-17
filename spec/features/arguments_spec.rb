# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Arguments', type: :feature do
  let(:actor) { :guest }
  let(:go_to_parent) {}
  let(:location) { '/argu/m/freetown_motion' }
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
      parent = '.FullResource div:nth-child(1) div.Card'
      go_to_parent
      fill_in_omniform(parent, click_to_open: true)
    end
  end

  context 'As guest' do
    let(:actor) { :guest }

    context 'continue as new user' do
      let(:after_post) do
        fill_in_registration_form
        verify_logged_in
        finish_setup
        expect(page).to have_current_path("#{location}/pros/new")
        wait_for { page }.to have_button 'Save'
        click_button 'Save'
        expect_argument_posted
      end
      it_behaves_like 'post argument'
    end

    context 'continue as existing user' do
      let(:after_post) do
        login('user1@example.com', open_modal: false)
        expect(page).to have_current_path("#{location}/pros/new")
        wait_for { page }.to have_button 'Save'
        click_button 'Save'
        expect_argument_posted
      end
      it_behaves_like 'post argument'
    end
  end

  context 'As user' do
    let(:actor) { 'user1@example.com' }
    it_behaves_like 'post argument'

    context 'question#show' do
      let(:location) { '/argu/q/freetown_question' }
      let(:result_element) { '.Column .CardList' }
      let(:parent_resource) { 'https://argu.localtest/argu/m/question_motion' }
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
      cancel_setup
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
    wait_until_loaded
    scope =
      resource_selector(
        parent_resource,
        element: omniform_parent
      )

    within scope do
      wait_for { page }.to have_content('Share a response...')
      click_button 'Share a response...' if click_to_open
      wait_for { page }.to have_button(@side.capitalize)
      click_button @side.capitalize
      wait_for { page }.to have_field field_name('http://schema.org/name')
      fill_in field_name('http://schema.org/name'), with: title
      fill_in field_name('http://schema.org/text'), with: content
      find('button[type=submit]').click
    end

    after_post
  end

  def expect_argument_posted
    wait_for { page }.to(
      have_snackbar(
        "#{@side.capitalize} published."
      )
    )
    wait_until_loaded
    wait_for { page }.to have_content title
    within resource_selector("#{parent_resource}/#{@side}s", element: result_element) do
      wait_for { page }.to have_content title
      wait_for { page }.to have_content content if expect_argument_content
    end
  end
end
