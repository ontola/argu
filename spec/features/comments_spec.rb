# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Comments', type: :feature do
  let(:actor) { :guest }
  let(:location) { '/argu/m/freetown_motion' }
  let(:content) { 'Content of comment' }
  let(:go_to_parent) do
    select_tab('Comments')
  end
  let(:after_post) do
    expect_comment_posted
  end

  shared_examples_for 'post comment' do
    before do
      as actor, location: location
    end

    example 'from card section' do
      go_to_parent
      fill_in_omniform(click_to_open: true)
      after_post
    end
  end

  context 'As guest' do
    let(:actor) { :guest }

    context 'continue as new user' do
      let(:after_post) do
        fill_in_registration_form
        verify_logged_in
        finish_setup
        expect(page).to have_current_path("#{location}/c/new")
        wait_for { page }.to have_button 'Publish'
        click_button 'Publish'
        expect_comment_posted
      end
      it_behaves_like 'post comment'
    end

    context 'continue as existing user' do
      let(:after_post) do
        login('user1@example.com', open_modal: false)
        expect(page).to have_current_path("#{location}/c/new")
        wait_for { page }.to have_button 'Publish'
        click_button 'Publish'
        expect_comment_posted
      end
      it_behaves_like 'post comment'
    end
  end

  context 'As user' do
    let(:actor) { 'user1@example.com' }
    it_behaves_like 'post comment'

    example 'post nested comment' do
      as actor, location: '/argu/pros/motion_argument'

      selector = resource_selector(
        'https://argu.localtest/argu/c/nested_argument_comment',
        element: '.Collection__Depth-1 > div > div'
      )
      within(selector) do
        wait_for { page }.to have_link('Reply')
        click_link('Reply')
        expect_form('/argu/c/nested_argument_comment/c')
        fill_in field_name('http://schema.org/text'), with: 'Nested comment'
        click_button('Publish')
        wait_for { page }.to have_snackbar('Comment published.')
      end

      wait_for { page }.to have_content('Show 1 additional replies...')
      expect(page).not_to have_content('Nested comment')
      click_link('Show 1 additional replies...')
      wait_for { page }.to have_content('Nested comment')
    end
  end

  context 'as invitee' do
    let(:location) { '/argu/tokens/valid_email_token' }
    let(:go_to_parent) do
      accept_token
      cancel_setup
      wait(30).for(page).to have_content('Fg motion title 3end')
      click_link 'Fg motion title 3end'
      select_tab('Comments')
    end
    let(:after_post) do
      accept_terms
      expect_comment_posted
    end
    it_behaves_like 'post comment'
  end

  private

  def fill_in_omniform(click_to_open: false)
    wait_until_loaded
    wait_for { page }.to have_content('Share your comment...')
    click_button 'Share your comment...' if click_to_open
    wait_for { page }.to have_field field_name('http://schema.org/text')
    fill_in field_name('http://schema.org/text'), with: content
    find('button[type=submit]').click
  end

  def expect_comment_posted
    wait_for { page }.to(
      have_snackbar('Comment published.')
    )
    wait_until_loaded
    wait_for { page }.to have_content content
  end
end
