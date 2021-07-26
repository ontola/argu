# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Budgets', type: :feature do
  let(:title) { 'My budget' }
  let(:content) { 'Explanation' }
  let(:motion_title) { 'Fg motion title 9' }

  example 'Create budget and add offers' do
    as 'staff@example.com', location: '/argu/freetown'
    wait_until_loaded
    find('.ContainerFloat .fa-plus').click
    wait_until_loaded
    click_link('New budget')
    fill_in field_name('http://schema.org/name'), with: title, fill_options: {clear: :backspace}
    fill_in_markdown field_name('http://schema.org/text'), with: content
    click_button('Save')
    expect_draft_message('Budget')
    expect_budget_content
    wait_until_loaded
    within resource_selector('https://argu.localtest/argu/budgets/80/offers', element: '.ContainerFloat') do
      find('.fa-plus').click
    end
    wait_for { page }.to have_content('New option')
    fill_in_select field_name('http://schema.org/itemOffered'), with: motion_title
    fill_in field_name('https://argu.co/ns/core#price'), with: 100
    click_button('Save')
    expect_budget_content
    expect_offer
  end

  example 'Guest submits budget' do
    as :guest, location: '/argu/freetown'
    go_to_budget
    add_order_detail(72)
    expect_cart_value(6)
    add_order_detail(73)
    expect_cart_value(9)
    add_order_detail(74)
    expect_cart_value(11, false)
    remove_order_detail(73)
    expect_cart_value(8)
    submit_cart
    wait_for{ page }.to have_snackbar('Your budget is submitted!')
    verify_order('guest', 8)
  end

  example 'Guest should not submit budget with wrong coupon' do
    as :guest, location: '/argu/freetown'
    go_to_budget
    add_order_detail(72)
    expect_cart_value(6)
    add_order_detail(74)
    expect_cart_value(8)
    submit_cart('WRONG')
    wait_for{ page }.to have_content('Coupon is not valid')
  end

  example 'User submits budget' do
    as :guest, location: '/argu/freetown'
    go_to_budget
    add_order_detail(72)
    expect_cart_value(6)
    login('user1@example.com')
    expect_cart_value(6)
    add_order_detail(74)
    expect_cart_value(8)
    submit_cart
    wait_for{ page }.to have_snackbar('Your budget is submitted!')
    logout
    verify_order('user_name_2', 8)
  end

  private

  def add_order_detail(id = 72)
    within resource_selector("https://argu.localtest/argu/offers/#{id}", element: '.Card') do
      click_button 'Add'
    end
  end

  def cart
    resource_selector('https://argu.localtest/argu/budgets/71/cart')
  end

  def expect_cart_value(value, valid = true)
    wait_until_loaded
    within cart do
      wait_for {page }.to have_content(value)
    end

    expect(page).to(valid ? have_link('Finish') : have_button('Finish', disabled: true))
    expect(page).not_to(valid ? have_button('Finish', disabled: true) : have_link('Finish'))
  end

  def expect_budget_content
    wait_for { page }.to have_current_path('/argu/budgets/80')
    wait_for { page }.to have_content(title)
    expect(page).to have_content(content)
  end

  def expect_offer
    wait_for { page }.to have_content(motion_title)
    expect(page).to have_content('100')
  end

  def go_to_budget
    wait_for { page }.to have_link('Fg budget title 1end')
    click_link 'Fg budget title 1end'
    wait_for{ page }.to have_content 'fg budget content 1end'
    wait_until_loaded
  end

  def remove_order_detail(id = 72)
    within resource_selector("https://argu.localtest/argu/offers/#{id}", element: '.Card') do
      click_button 'Remove'
    end
  end

  def submit_cart(coupon = 'COUPON1')
    within(cart) do
      click_link('Finish')
      end
    wait_for { page }.to have_current_path('/argu/budgets/71/orders/new')
    wait_until_loaded
    wait_for{ page }.to have_content('Fg motion title 10end')
    wait_for{ page }.to have_content('Fg motion title 9end')
    fill_in(field_name('https://argu.co/ns/core#coupon'), with: coupon)
    click_button('Save')
  end

  def verify_order(user, value)
    login('staff@example.com')
    go_to_menu_item('Orders')
    row = resource_selector('https://argu.localtest/argu/orders/80', element: 'tr')
    within row do
      expect(page).to have_content(user)
      expect(page).to have_content(value)
    end
  end
end
