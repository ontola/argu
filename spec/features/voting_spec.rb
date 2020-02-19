# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Voting', type: :feature do
  before do
    as actor, location: location
    before_vote
    wait(30).for(page).to have_content "fg motion content #{motion_sequence}end"
  end

  let(:actor) { :guest }
  let(:after_confirmation) { nil }
  let(:after_vote) do
    wait_for { page }.to have_snackbar 'Thanks for your vote!'
    expect_voted(side: @side)
  end
  let(:before_vote) {}

  shared_examples_for 'voting' do
    example 'remember vote' do
      vote_in_favour
      visit current_path
      expect_voted
    end

    example 'change vote' do
      vote_in_favour
      vote_against
      vote_in_favour
    end
  end

  shared_examples_for 'confirm vote' do
    example 'confirm vote' do
      vote_in_favour
      confirm
      expect_voted
      after_confirmation
    end
  end

  context 'on motion#show' do
    let(:location) { '/argu/m/38' }
    let(:motion_sequence) { 8 }

    context 'as guest' do
      it_behaves_like 'voting'

      context 'confirm as existing user' do
        let(:email) { 'user1@example.com' }
        let(:confirm) do
          login_to_confirm 'password'
          verify_logged_in
        end

        it_behaves_like 'confirm vote'
      end

      context 'confirm with wrong password' do
        let(:email) { 'user1@example.com' }
        let(:confirm) do
          login_to_confirm 'wrong password'
        end

        # @todo Wrong password behaviour
        # it_behaves_like 'confirm vote'
      end

      context 'confirm as new user' do
        let(:email) { 'new_user@example.com' }
        let(:confirm) do
          login_to_confirm
          wait_for_terms_notice
          click_button 'Confirm'
        end
        let(:after_confirmation) do
          wait_until_loaded
          wait_for { page }.to(
            have_content(
              'Please confirm your vote by clicking the link we\'ve sent to '\
              'new_user@example.com'
            )
          )
          expect_voted
          within navbar do
            wait_for { count_bubble_count }.to have_content '1'
          end
          # @todo add link to notification in UI
          # click_link 'Notifications'
          visit 'https://argu.localtest/argu/n'
          wait_for { page }.to(
            have_content("Please confirm your vote by clicking the link we've sent to new_user@example.com")
          )
          expect_email(:confirm_vote_email)
          expect(confirm_vote_email.body).to have_content('In favour of Fg motion title 8end')
          visit confirm_vote_email.links.last
          wait_for { page }.to have_snackbar('Your account has been confirmed.')
          wait_for { page }.to have_content('Choose a password')
          fill_in 'https://argu.co/ns/core#password', with: 'new password'
          fill_in 'https://argu.co/ns/core#passwordConfirmation', with: 'new password'
          click_button 'Save'
          wait_for { page }.to have_content('Set how you will be visible to others on Argu')
          wait_for { page }.to have_snackbar('Your password has been updated successfully.')
          logout
          login('new_user@example.com', 'new password')
          visit 'https://argu.localtest/argu/n'
          wait_for { page }.to have_content('Finish your profile to be more recognizable.')
        end

        it_behaves_like 'confirm vote'
      end
    end

    context 'as user' do
      let(:actor) { 'user1@example.com' }

      it_behaves_like 'voting'
    end

    context 'as invitee' do
      let(:location) { '/argu/tokens/valid_email_token' }
      let(:motion_sequence) { 3 }
      let(:after_vote) do
        accept_terms
        wait_for { page }.to have_snackbar 'Thanks for your vote!'
        expect_voted(side: @side)
      end
      let(:before_vote) { accept_token }

      example 'vote' do
        click_link "Fg motion title #{motion_sequence}end"
        vote_in_favour
        after_vote
      end
    end
  end

  context 'on question#show' do
    let(:location) { '/argu/q/41' }
    let(:motion_sequence) { 9 }

    context 'as guest' do
      it_behaves_like 'voting'
    end

    context 'as user' do
      let(:actor) { 'user1@example.com' }

      it_behaves_like 'voting'
    end
  end

  private

  def login_to_confirm(password = nil)
    expect(page).to have_content 'Confirm your vote via e-mail'
    wait_until_loaded

    fill_in placeholder: 'email@example.com', with: email
    click_button 'Confirm'
    return unless password

    fill_in id: 'password', with: password
    click_button 'Continue'
  end

  def confirm_vote_email
    @confirm_vote_email ||= mailcatcher_email(to: [email], subject: 'Confirm your vote')
  end

  def vote_in_favour
    @side = 'yes'
    wait_for { page }.to have_content 'Agree'
    click_button 'Agree'
    after_vote
  end

  def vote_against
    @side = 'no'
    wait_for { page }.to have_content 'Disagree'
    click_button 'Disagree'
    after_vote
    wait_for { page }.to have_snackbar 'Thanks for your vote!'
    expect_voted(side: @side)
  end

  def expect_voted(side: 'yes')
    wait_for { page }.to have_css ".Button--variant-#{side}.Button--active"
  end
end
