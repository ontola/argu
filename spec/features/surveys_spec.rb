# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Surveys', type: :feature do
  let(:reward) { false }

  context 'open survey' do
    let(:survey_path) { '/argu/surveys/76' }

    example 'Guest submits open survey' do
      as :guest, location: survey_path
      start_survey
      fill_in_survey
      expect_submitted
    end

    example 'User submits open survey' do
      as 'user1@example.com', location: survey_path
      start_survey
      fill_in_survey
      expect_submitted
    end
  end

  context 'reward survey' do
    let(:reward) { true }
    let(:survey_path) { '/argu/surveys/78' }

    example 'Guest submits reward survey' do
      as :guest, location: survey_path
      start_survey('COUPON1')
      visit survey_path
      continue_survey
      fill_in_survey
      expect_submitted
    end

    example 'Guest continues reward survey' do
      as :guest, location: survey_path
      start_survey('COUPON1')
      fill_in_survey
      expect_submitted
    end

    example 'Guest should not submit reward survey with wrong coupon' do
      as :guest, location: survey_path
      start_survey('WRONG')
      wait_for{ page }.to have_content('Coupon is not valid')
    end

    example 'User submits reward survey' do
      as 'user1@example.com', location: survey_path
      start_survey('COUPON1')
      fill_in_survey
      expect_submitted
    end
  end

  private

  def continue_survey
    wait_for { page }.to have_button('Continue')
    click_button('Continue')
  end

  def expect_submitted
    wait_for { page }.to have_content('Thank you for your response')
    visit survey_path
    wait_for { page }.to have_content('Thank you for your response')
    if reward
      wait_for { page }.to have_button('Claim reward')
    else
      wait_until_loaded
      expect(page).not_to have_button('Claim reward')
    end
  end

  def fill_in_survey
    page.within_frame(:css, 'iframe[title="typeform-embed"]') do
      wait_for { page }.to have_button('Submit')
      click_button('Submit')
    end
  end

  def start_survey(coupon = nil)
    wait_for { page }.to have_button('Start')
    if coupon
      wait_for { page }.to have_content('Coupon')
      fill_in(field_name('https://argu.co/ns/core#coupon'), with: coupon)
    else
      wait_until_loaded
      expect(page).not_to have_content('Coupon')
    end
    click_button('Start')
  end
end
