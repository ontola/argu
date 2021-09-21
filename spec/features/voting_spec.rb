# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Voting', type: :feature do
  before do
    as actor, location: location
    before_vote
    wait(30).for(page).to have_content motion_content
  end

  let(:actor) { :guest }
  let(:after_confirmation) { nil }
  let(:after_vote) do
    wait_for { page }.to have_snackbar 'Thanks for your vote!'
    expect_voted(button: @button)
  end
  let(:before_vote) {}
  let(:vote_counts) { { Agree: 0, Disagree: 0 }.with_indifferent_access }
  let(:vote_diff) { 0 }

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
      after_confirmation
      expect_voted(count: vote_counts[@button] + 1)
    end
  end

  context 'on motion#show' do
    let(:location) { '/argu/m/freetown_motion' }
    let(:motion_content) { 'freetown_motion-text' }

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
          finish_setup
          expect_voted
          within navbar do
            wait_for { count_bubble_count }.to have_content '1'
          end
          go_to_user_page('Notifications')
          wait_for { page }.to(
            have_content("Please confirm your vote by clicking the link we've sent to new_user@example.com")
          )
          expect_email(:confirm_vote_email)
          expect(confirm_vote_email.body).to have_content('Freetown_motion-title: Agree')
          visit confirm_vote_email.links.last
          wait_for { page }.to have_snackbar('Your account has been confirmed.')
          wait_for { page }.to have_content('Set your password')
          fill_in field_name('https://ns.ontola.io/core#password'), with: 'new password'
          fill_in field_name('https://ns.ontola.io/core#passwordConfirmation'), with: 'new password'
          click_button 'Save'
          wait_for { page }.to have_snackbar('Your password has been updated successfully.')
          logout
          login('new_user@example.com', 'new password')
          visit location
        end

        it_behaves_like 'confirm vote'
      end
    end

    context 'as user' do
      let(:vote_diff) { 1 }
      let(:actor) { 'user1@example.com' }

      it_behaves_like 'voting'
    end

    context 'as invitee' do
      let(:vote_diff) { 1 }
      let(:location) { '/argu/tokens/valid_email_token' }
      let(:motion_content) { 'fg motion content 3end' }
      let(:after_vote) do
        accept_terms
        wait_for { page }.to have_snackbar 'Thanks for your vote!'
        expect_voted(button: @button)
      end
      let(:before_vote) do
        accept_token
        cancel_setup
      end

      example 'vote' do
        click_link 'Fg motion title 3end'
        vote_in_favour
        after_vote
      end
    end
  end

  context 'on question#show' do
    let(:location) { '/argu/q/freetown_question' }
    let(:motion_content) { 'question_motion-text' }
    let(:vote_counts) { { Agree: 2, Disagree: 0 }.with_indifferent_access }

    context 'as guest' do
      it_behaves_like 'voting'
    end

    context 'as user' do
      let(:vote_diff) { 1 }
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

    fill_in field_name('https://ns.ontola.io/core#password'), with: password
    click_button 'Continue'
  end

  def confirm_vote_email
    @confirm_vote_email ||= mailcatcher_email(to: [email], subject: 'Confirm your vote')
  end

  def link_race_condition_patch
    sleep(2)
  end

  def vote_in_favour
    wait_until_loaded
    @button = 'Agree'
    wait_for { page }.to have_content @button
    link_race_condition_patch
    click_button @button
    after_vote
  end

  def vote_against
    wait_until_loaded
    @button = 'Disagree'
    wait_for { page }.to have_content @button
    link_race_condition_patch
    click_button @button
    after_vote
    wait_for { page }.to have_snackbar 'Thanks for your vote!'
    expect_voted(button: @button)
  end

  def expect_voted(button: 'Agree', count: nil)
    button_css = '.Button--active'
    wait_for { page }.to have_css button_css
    wait_until_loaded
    within button_css do
      wait_for{ page }.to have_content(button)
    end

    expected_count = count || vote_counts[button] + vote_diff
    if expected_count == 0
      expect(page).to have_selector(button_css)
      expect(page).not_to have_selector(button_css, text: /\(/)
    else
      expect(page).to have_selector(button_css, text: /\(#{expected_count}\)/)
    end
  end
end
