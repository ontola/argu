# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Surveys', type: :feature do
  let(:reward) { false }

  context 'open survey' do
    let(:survey_path) { '/argu/surveys/typeform_survey' }

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
    let(:survey_path) { '/argu/surveys/reward_survey' }

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
    Capybara.current_session.driver.with_playwright_page do |page|
      within_dialog do
        wait_for { page.locator('text=Thank you for your response').visible? }.to be_truthy
      end
      visit survey_path
      wait_for { page.locator('text=Thank you for your response').visible? }.to be_truthy

      if reward
        wait_for { page.locator('text=Claim reward').visible? }.to be_truthy
        wait_for { page }.to have_button('Claim reward')
      else
        wait_until_loaded
        wait_for { page.locator('text=Claim reward').count }.to eq 0
      end
    end
  end

  def fill_in_survey
    wait_until_loaded
    wait_for { page }.to have_css('iframe[title="typeform-embed"]')
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
