# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Comments', type: :feature do
  let(:actor) { :guest }
  let(:location) { '/argu/m/38' }
  let(:content) { 'Content of comment' }
  let(:go_to_parent) {}
  let(:after_post) do
    expect_comment_posted
  end

  shared_examples_for 'post comment' do
    before do
      as actor, location: location
    end

    example 'from card section' do
      parent = '.FullResource div:nth-child(1) div.Card'
      go_to_parent
      fill_in_omniform(parent, click_to_open: true)
      after_post
    end
  end

  context 'As guest' do
    let(:actor) { :guest }

    context 'continue as new user' do
      let(:after_post) do
        fill_in_registration_form
        verify_logged_in
        expect(page).to have_current_path("#{location}/c/new")
        wait_for { page }.to have_button 'Save'
        click_button 'Save'
        expect_comment_posted
      end
      it_behaves_like 'post comment'
    end

    context 'continue as existing user' do
      let(:after_post) do
        login('user1@example.com', open_modal: false)
        expect(page).to have_current_path("#{location}/c/new")
        wait_for { page }.to have_button 'Save'
        click_button 'Save'
        expect_comment_posted
      end
      it_behaves_like 'post comment'
    end
  end

  context 'As user' do
    let(:actor) { 'user1@example.com' }
    it_behaves_like 'post comment'
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
      expect_comment_posted
    end
    it_behaves_like 'post comment'
  end

  private

  def fill_in_omniform(omniform_parent, click_to_open: false)
    wait_until_loaded
    scope =
      resource_selector(
        page.current_url,
        element: omniform_parent
      )

    within scope do
      click_button 'Share a response...' if click_to_open
      fill_in 'http://schema.org/text', with: content
      within '.Form__footer--right' do
        find('.Button--submit').click
      end
    end
  end

  def expect_comment_posted
    wait_for { page }.to(
      have_snackbar(
        "Comment published successfully. It can take a few moments before it's visible on other pages."
      )
    )
    wait_until_loaded
    within resource_selector("#{page.current_url}/c", element: '.MuiContainer-root > div') do
      wait_for { page }.to have_content content
    end
  end
end
