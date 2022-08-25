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
      link_race_condition_patch
      downvote
      link_race_condition_patch
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
    wait_for { page }.to have_css upvote_button
    playwright_page.click(upvote_button)
    return unless success

    wait_for { page }.to have_snackbar succeed_message
    expect_voted
  end

  def downvote(success: true)
    wait_for { page }.to have_css downvote_button
    playwright_page.click(downvote_button)
    return unless success

    wait_for { page }.to have_snackbar 'Vote deleted successfully'
    expect_not_voted
  end

  def expect_voted
    pro_column = resource_selector("#{playwright_page.url}/pros", element: "#{test_id_selector('column')} > div")
    wait_for { pro_column.locator(downvote_button).visible? }.to be_truthy
    button = pro_column.locator(downvote_button)

    button.locator("text=#{expected_count}")
  end

  def expect_not_voted
    pro_column = resource_selector("#{playwright_page.url}/pros", element: "#{test_id_selector('column')} > div")
    wait_for { pro_column.locator(upvote_button).visible? }.to be_truthy
    button = pro_column.locator(upvote_button)

    button.locator("text=1")
  end

  def downvote_button
    'button[aria-pressed=true][title=Upvote]'
  end
  def upvote_button
    'button[aria-pressed=false][title=Upvote]'
  end

  def link_race_condition_patch
    sleep(2)
  end
end
