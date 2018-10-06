# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Voting', type: :feature do
  before do
    as actor, location: location
    wait_for(page).to have_content "fg motion content #{motion_sequence}end"
  end

  let(:actor) { :guest }
  let(:after_confirmation) { nil }

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
    let(:location) { '/argu/m/32' }
    let(:motion_sequence) { 8 }

    context 'as guest' do
      it_behaves_like 'voting'

      context 'confirm as existing user' do
        let(:email) { 'user1@example.com' }
        let(:confirm) do
          login_to_confirm 'password'
          verify_logged_in
        end

        # @todo Transfer guest vote to new user
        # it_behaves_like 'confirm vote'
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
          wait_for(page).to(
            have_content('Door je te registreren ga je akkoord met de algemene voorwaarden en de privacy policy.')
          )
          click_button 'Bevestig'
        end
        let(:after_confirmation) do
          wait_for(page).to(
            have_content(
              'Vergeet niet je stem te bevestigen door op de link te klikken die we je hebben gemaild naar '\
              'new_user@example.com'
            )
          )
          expect_voted
          within sidebar do
            wait_for { count_bubble_count }.to have_content '1'
          end
          click_link 'Notifications'
          wait_for(page).to(
            have_content('Please confirm your vote by clicking the link we\'ve send to new_user@example.com')
          )
          expect_email(:confirm_vote_email)
          expect(confirm_vote_email.body).to have_content('In favour of Fg motion title 8end')
          visit confirm_vote_email.links.last
          wait_for(page).to have_content('Your account has been confirmed.')
          wait_for(page).to have_content('Choose a password')
          fill_in placeholder: 'At least 8 characters.', with: 'new password'
          fill_in placeholder: 'Same as above', with: 'new password'
          click_button 'Save'
          wait_for(page).to have_content('Set how you will be visible to others on Argu')
          wait_for(page).to have_content('Your password has been updated successfully.')
          logout
          login('new_user@example.com', 'new password')
          click_link 'Notifications'
          wait_for(page).to have_content('Finish your profile to be more recognizable.')
        end

        it_behaves_like 'confirm vote'
      end
    end

    context 'as user' do
      let(:actor) { 'user1@example.com' }

      it_behaves_like 'voting'
    end
  end

  context 'on question#show' do
    let(:location) { '/argu/q/35' }
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
    expect(page).to have_content 'BEVESTIG JOUW STEM VIA EMAIL'
    fill_in placeholder: 'email@example.com', with: email
    click_button 'Ga verder'
    return unless password

    fill_in name: 'password', with: password
    click_button 'Verder'
  end

  def confirm_vote_email
    @confirm_vote_email ||= mailcatcher_email(to: [email], subject: 'Confirm your vote')
  end

  def vote_in_favour
    wait_for(page).to have_content 'Agree'
    click_button 'Agree'
    wait_for(page).to have_content 'Thanks for your vote!'
    expect_voted
  end

  def vote_against
    wait_for(page).to have_content 'Disagree'
    click_button 'Disagree'
    wait_for(page).to have_content 'Thanks for your vote!'
    expect_voted(side: 'no')
  end

  def expect_voted(side: 'yes')
    wait_for(page).to have_css ".Button--variant-#{side}.Button--active"
  end
end
