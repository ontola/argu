# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upvoting', type: :feature do
  before do
    as actor, location: location
    before_vote
    wait_for { page }.to have_content "fg motion content #{motion_sequence}end"
  end

  let(:actor) { :guest }
  let(:before_vote) {}
  let(:expected_count) { 1 }
  let(:location) { '/argu/m/38' }
  let(:motion_sequence) { 9 }

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
    let(:expected_count) { 0 }

    it_behaves_like 'upvoting'
  end

  context 'as user' do
    let(:actor) { 'user1@example.com' }

    it_behaves_like 'upvoting'
  end

  context 'as invitee' do
    let(:before_vote) { accept_token }
    let(:location) { '/argu/tokens/valid_email_token' }
    let(:motion_sequence) { 3 }

    example 'remember upvote' do
      click_link "Fg motion title #{motion_sequence}end"
      upvote(success: false)
      accept_terms
      expect_voted
      visit current_path
      expect_voted
    end
  end

  private

  def upvote(success: true)
    wait_for { page }.to have_content 'Upvote'
    click_button 'Upvote'
    return unless success

    wait_for { page }.to have_snackbar 'Thanks for your vote!'
    click_link class: 'MuiIconButton-root'
    expect_voted
  end

  def downvote(success: true)
    wait_for { page }.to have_content 'Upvote'
    click_button 'Upvote'
    return unless success

    wait_for { page }.to have_snackbar 'Vote deleted successfully'
    click_link class: 'MuiIconButton-root'
    expect_not_voted
  end

  def expect_voted
    wait_for { page }.to have_css '.Button--variant-yes.Button--active'
    expect(page).to have_content "Upvote#{expected_count > 0 ? " (#{expected_count})" : ''}"
  end

  def expect_not_voted
    wait_for { page }.not_to have_css '.Button--variant-yes.Button--active'
    expect(page).to have_content 'Upvote'
    expect(page).not_to have_content 'Upvote (1)'
  end
end
