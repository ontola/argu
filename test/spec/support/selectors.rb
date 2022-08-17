# frozen_string_literal: true

module Selectors
  def playwright_page
    browser = Capybara.current_session.driver.send(:browser)
    browser.send(:assert_page_alive)
    browser.instance_variable_get(:@playwright_page)
  end

  def add_child_to_form(field)
    click_button field
  end

  def application_menu
    playwright_page.locator('.CID-AppMenu')
  end

  def collection_float_button(button, collection: nil)
    prepend = collection ? "div[resource='#{collection}'] " : ''

    button_css = "#{prepend}a[title='#{button}']"
    wait_for { page }.to have_css(button_css)

    playwright_page.locator(button_css)
  end

  def count_bubble_count
    playwright_page.locator('[title="Click to read your notifications"]')
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
    playwright_page.locator('#App__container > .MuiAppBar-root')
  end

  def details_bar
    playwright_page.locator(test_selector('DetailsBar'))
  end

  def navbar_tabs
    playwright_page.locator('.MuiAppBar-root .CID-NavBarContentItems')
  end

  def main_content
    playwright_page.locator('#start-of-content')
  end

  def resource_selector(iri, element: 'div', child: nil, parent: nil)
    selector = "#{element}[resource='#{iri}'] #{child}"

    (parent || playwright_page).locator(selector)
  end

  def test_selector(selector)
    "[data-test='#{selector}']"
  end

  def test_id_selector(selector)
    "[data-testid='#{selector}']"
  end
end
