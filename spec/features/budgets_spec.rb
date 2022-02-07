# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Budgets', type: :feature do
  let(:title) { 'My budget' }
  let(:content) { 'Explanation' }
  let(:motion_title) { 'Freetown_motion-title' }

  example 'Create budget and add offers' do
    as 'staff@example.com', location: '/argu/freetown'
    wait_until_loaded
    find('h2', text: 'Topics').click
    Capybara.current_session.driver.with_playwright_page do |page|
      page.wait_for_selector(".CID-CollectionHeaderFloat .fa-plus")
    end
    find('.CID-CollectionHeaderFloat .fa-plus').click
    wait_until_loaded
    within_dialog do
      click_link('Budget')
    end
    fill_in field_name('http://schema.org/name'), with: title, fill_options: {clear: :backspace}
    fill_in_markdown field_name('http://schema.org/text'), with: content
    click_button('Save')
    expect_draft_message('Budget')
    expect_budget_content
    wait_until_loaded
    find('h2', text: 'Options').click
    collection_float_button("https://argu.localtest/argu/budgets/#{next_id}/offers").click

    Capybara.current_session.driver.with_playwright_page do |page|
      page.locator('text=New option')
    end
    fill_in_select field_name('http://schema.org/itemOffered'), with: motion_title
    fill_in field_name('https://argu.co/ns/core#price'), with: 100
    click_button('Save')
    expect_budget_content
    expect_offer
  end

  example 'Guest submits budget' do
    as :guest, location: '/argu/freetown'
    go_to_budget
    add_order_detail(:offer_600)
    expect_cart_value(6)
    add_order_detail(:offer_300)
    expect_cart_value(9)
    add_order_detail(:offer_200)
    expect_cart_value(11, false)
    remove_order_detail(:offer_300)
    expect_cart_value(8)
    submit_cart
    wait_for { page }.to have_snackbar('Your budget is submitted!')
    verify_order('guest', 8)
  end

  example 'Guest should not submit budget with wrong coupon' do
    as :guest, location: '/argu/freetown'
    go_to_budget
    add_order_detail(:offer_600)
    expect_cart_value(6)
    add_order_detail(:offer_200)
    expect_cart_value(8)
    submit_cart('WRONG')
    wait_for{ page }.to have_content('Coupon is not valid')
  end

  example 'User submits budget' do
    as :guest, location: '/argu/freetown'
    go_to_budget
    add_order_detail(:offer_600)
    expect_cart_value(6)
    login('user1@example.com')
    expect_cart_value(6)
    add_order_detail(:offer_200)
    expect_cart_value(8)
    submit_cart
    wait_for{ page }.to have_snackbar('Your budget is submitted!')
    logout
    verify_order('user_name_2', 8)
  end

  private

  def add_order_detail(id = :offer_600)
    scope = resource_selector("https://argu.localtest/argu/offers/#{id}", element: '.CID-Card')
    scope.locator('text=Add').click
  end

  def cart
    resource_selector('https://argu.localtest/argu/budgets/budget_shop/cart')
  end

  def expect_cart_value(value, valid = true)
    wait_until_loaded

    cart.locator("text=#{value}")

    expect(page).to(valid ? have_link('Finish') : have_button('Finish', disabled: true))
    expect(page).not_to(valid ? have_button('Finish', disabled: true) : have_link('Finish'))
  end

  def expect_budget_content
    wait_for { page }.to have_current_path("/argu/budgets/#{next_id}")
    wait_for { page }.to have_content(title)
    expect(page).to have_content(content)
  end

  def expect_offer
    wait_for { page }.to have_content(motion_title)
    expect(page).to have_content('100')
  end

  def go_to_budget
    wait_for { page }.to have_link('Budget_shop-title')
    click_link 'Budget_shop-title'
    wait_for{ page }.to have_content 'budget_shop-text'
    wait_until_loaded
  end

  def remove_order_detail(id = :offer_600)
    scope = resource_selector("https://argu.localtest/argu/offers/#{id}", element: '.CID-Card')
    scope.locator('text=Remove').click
  end

  def submit_cart(coupon = 'COUPON1')
    Capybara.current_session.driver.with_playwright_page do |page|
      page.expect_navigation do
        cart.locator('text=Finish').click
      end

      page.locator("text=Question_motion-title")
      page.locator("text=Freetown_motion-title")
      page.fill(field_selector('https://argu.co/ns/core#coupon'), coupon)
      page.locator('text=Save').click
    end
  end

  def verify_order(user, value)
    login('staff@example.com')
    select_tab('Orders')
    wait_until_loaded
    row = resource_selector("https://argu.localtest/argu/orders/#{next_id}", element: 'tr')

    row.locator("text=#{user}")
    row.locator("text=#{value}")
  end
end
