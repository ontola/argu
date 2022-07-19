# frozen_string_literal: true

module Selectors
  def add_child_to_form(field)
    click_button field
  end

  def application_menu
    Capybara.current_session.driver.with_playwright_page do |page|
      page.locator('.CID-AppMenu')
    end
  end

  def collection_float_button(button, collection: nil)
    prepend = collection ? "div[resource='#{collection}'] " : ''

    button_css = "#{prepend}a[title='#{button}']"
    wait_for { page }.to have_css(button_css)
    find(button_css)
  end

  def count_bubble_count
    Capybara.current_session.driver.with_playwright_page do |page|
      page.locator('[title="Click to read your notifications"]')
    end
  end

  def field_name(*names)
    names
      .map { |name| name.is_a?(String) ? Base64.encode64(name).gsub("\n", '') : name }
      .join('.')
  end

  def field_selector(*names)
    name = field_name(*names)
    "[name='#{name}']"
  end

  def navbar
    Capybara.current_session.driver.with_playwright_page do |page|
      page.locator('#App__container > .MuiAppBar-root')
    end
  end

  def details_bar
    Capybara.current_session.driver.with_playwright_page do |page|
      page.locator(test_selector('DetailsBar'))
    end
  end

  def navbar_tabs
    Capybara.current_session.driver.with_playwright_page do |page|
      page.locator('.MuiAppBar-root .CID-NavBarContentItems')
    end
  end

  def main_content
    Capybara.current_session.driver.with_playwright_page do |page|
      page.locator('#start-of-content')
    end
  end

  def resource_selector(iri, element: 'div', child: nil, parent: nil)
    Capybara.current_session.driver.with_playwright_page do |page|
      selector = "#{element}[resource='#{iri}'] #{child}"

      (parent || page).locator(selector)
    end
  end

  def test_selector(selector)
    "[data-test='#{selector}']"
  end

  def test_id_selector(selector)
    "[data-testid='#{selector}']"
  end
end
