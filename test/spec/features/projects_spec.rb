# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects', type: :feature do
  let(:title) { 'Project title' }
  let(:content) { 'Project content' }

  example 'staff posts a project' do
    as 'staff@example.com', location: '/argu/freetown/projects/new'
    expect_form('/argu/freetown/projects', advanced: true)
    fill_in_form
    expect_draft_message('Project')
    expect_content
    expect_phase_resource_content('Fill in survey')
    select_phase('Collect ideas')
    expect_phase_resource_content('Do you have a good idea?')
    select_phase('Feedback')
    expect_phase_resource_content('Comments')
    add_phase
    select_phase('New phase')
    expect_phase_resource_content('Do you have a good idea?')
  end

  private

  def expect_content(path: "projects/#{next_id}")
    wait_for { page }.to have_content(title)
    expect(page).to have_content(content)
    expect(page).to have_current_path("/argu/#{path}")
  end

  def expect_phase_resource_content(content)
    wait_for { page }.to have_css('section[aria-label="Participate"]')
    within('section[aria-label="Participate"]') do
      wait_for { page }.to have_content(content)
    end
  end

  def fill_in_form
    fill_in field_name('http://schema.org/name'), with: title
    fill_in_markdown field_name('http://schema.org/text'), with: content
    click_button 'Save draft'
  end

  def select_phase(label)
    wait_for { page }.to have_link(label)
    click_link(label)
  end

  def add_phase
    find('.MuiStepLabel-root .fa-plus').click
    wait_for { page }.to have_content('New phase')
    fill_in field_name('http://schema.org/name'), with: 'New phase'
    fill_in_markdown field_name('http://schema.org/text'), with: 'Phase content'
    fill_in_select(field_name('https://argu.co/ns/core#resourceType'), with: 'Challenge')
    click_button 'Save'
  end
end
