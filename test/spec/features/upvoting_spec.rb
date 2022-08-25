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
  let(:succeed_message) { 'Thanks for your vote!' }
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
    let(:succeed_message) { 'Please login to confirm your vote!' }

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
    playwright_page.click('button[title=Upvote]')
    return unless success

    wait_for { page }.to have_snackbar succeed_message
    playwright_page.click('button[title=Upvote]')
    expect_voted
  end

  def downvote(success: true)
    wait_for { page }.to have_css 'button[title=Upvote]'
    playwright_page.click('button[title=Upvote]')
    return unless success

    wait_for { page }.to have_snackbar 'Vote deleted successfully'
    playwright_page.click('button[title=Upvote]')
    expect_not_voted
  end

  def expect_voted
    pro_column = resource_selector("#{playwright_page.url}/pros", element: "#{test_id_selector('column')} > div")
    wait_for { pro_column.locator('button[aria-pressed=true][title=Upvote]').visible? }.to be_truthy
    button = pro_column.locator('button[aria-pressed=true][title=Upvote]')

    button.locator("text=#{expected_count}")
  end

  def expect_not_voted
    pro_column = resource_selector("#{playwright_page.url}/pros", element: "#{test_id_selector('column')} > div")
    wait_for { pro_column.locator('button[aria-pressed=true]').count }.to eq 0
    button = pro_column.locator('button[title=Upvote]')

    button.locator("text=1")
  end
end
