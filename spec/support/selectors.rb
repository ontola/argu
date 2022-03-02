# frozen_string_literal: true

module Selectors
  def add_child_to_form(field)
    click_button field
  end

  def application_menu
    wait_for { page }.to have_css('.CID-AppMenu')
    page.find('.CID-AppMenu')
  end

  def collection_float_button(collection)
    resource_selector(
      collection,
      child: '.CID-CollectionHeaderFloat .fa-plus'
    )
  end

  def count_bubble_count(element = nil)
    wait_for { page }.to have_css('[title="Click to read your notifications"]')
    found = page.find('[title="Click to read your notifications"]')
    return found if element.nil?

    found.find(element)
  end

  def field_name(*names)
    names.map { |name| name.is_a?(String) ? Base64.encode64(name).gsub("\n", '') : name }.join('.')
  end

  def navbar(element = nil)
    found = page.find('#App__container > .MuiAppBar-root')
    return found if element.nil?

    found.find(element)
  end

  def details_bar
    wait_for { page }.to have_css(test_selector('DetailsBar'))

    page.find(test_selector('DetailsBar'))
  end

  def navbar_tabs(element = nil)
    wait_for { page }.to have_css('.MuiAppBar-root .CID-NavBarContentItems')
    found = page.find('.MuiAppBar-root .CID-NavBarContentItems')
    return found if element.nil?

    found.find(element)
  end

  def main_content(element = nil)
    found = page.find('#start-of-content')
    return found if element.nil?

    found.find(element)
  end

  def resource_selector(iri, element: 'div', child: nil, parent: page)
    selector = "#{element}[resource='#{iri}'] #{child}"
    wait_for { parent }.to have_css selector
    parent.find(selector)
  end

  def test_selector(selector)
    "[data-test='#{selector}']"
  end

  def test_id_selector(selector)
    "[data-testid='#{selector}']"
  end
end
