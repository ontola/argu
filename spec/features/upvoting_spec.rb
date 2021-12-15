# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upvoting', type: :feature do
  before do
    as actor, location: location
    before_vote
    wait_for { page }.to have_content motion_content
  end

  let(:actor) { :guest }
  let(:before_vote) {}
  let(:expected_count) { 2 }
  let(:location) { '/argu/m/freetown_motion' }
  let(:motion_content) { 'freetown_motion-text' }

  shared_examples_for 'upvoting' do
    example 'remember upvote' do
      upvote
      visit current_path
      expect_voted
    end

    example 'change upvote' do
      upvote
      downvote
      upvote
    end
  end

  context 'as guest' do
    let(:expected_count) { 1 }

    it_behaves_like 'upvoting'
  end

  context 'as user' do
    let(:actor) { 'user1@example.com' }

    it_behaves_like 'upvoting'
  end

  context 'as invitee' do
    let(:before_vote) do
      accept_token
      cancel_setup
    end
    let(:location) { '/argu/tokens/valid_email_token' }
    let(:motion_content) { 'fg motion content 3end' }

    example 'remember upvote' do
      click_link 'Fg motion title 3end'
      upvote(success: false)
      accept_terms
      expect_voted
      visit current_path
      expect_voted
    end
  end

  private

  def upvote(success: true)
    wait_for { page }.to have_css 'button[title=Upvote]'
    find('button[title=Upvote]').click
    return unless success

    wait_for { page }.to have_snackbar 'Thanks for your vote!'
    click_link class: 'MuiIconButton-root'
    expect_voted
  end

  def downvote(success: true)
    wait_for { page }.to have_css 'button[title=Upvote]'
    find('button[title=Upvote]').click
    return unless success

    wait_for { page }.to have_snackbar 'Vote deleted successfully'
    click_link class: 'MuiIconButton-root'
    expect_not_voted
  end

  def expect_voted
    within resource_selector("#{page.current_url}/pros", element: 'div.Collection') do
      wait_for { page }.to have_css 'button[aria-pressed=true][title=Upvote]'
      within find('button[aria-pressed=true][title=Upvote]') do
        expect(page).to have_content expected_count
      end
    end
  end

  def expect_not_voted
    within resource_selector("#{page.current_url}/pros", element: 'div.Collection') do
      wait_for { page }.not_to have_css 'button[aria-pressed=true]'
      within find('button[title=Upvote]') do
        expect(page).to have_content '1'
        expect(page).not_to have_content '2'
      end
    end
  end
end
