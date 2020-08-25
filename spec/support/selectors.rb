# frozen_string_literal: true

module Selectors
  def application_menu
    wait_for { page }.to have_css('.AppMenu')
    page.find('.AppMenu')
  end

  def application_menu_button
    wait_for { page }.to have_button(text: 'Menu')
    page.find(:button, text: 'Menu')
  end

  def count_bubble_count(element = nil)
    wait_for { page }.to have_css('.CountBubble__number')
    found = page.find('.CountBubble__number')
    return found if element.nil?

    found.find(element)
  end

  def field_name(*names)
    names.map { |name| name.is_a?(String) ? Base64.encode64(name).gsub("\n", '') : name }.join('.')
  end

  def navbar(element = nil)
    found = page.find('.App__container > .MuiAppBar-root')
    return found if element.nil?

    found.find(element)
  end

  def details_bar(parent: resource_selector(page.current_url, element: '.Card'))
    within(parent) do
      wait_for { page }.to have_css('.DetailsBar')

      page.find('.DetailsBar')
    end
  end

  def navbar_tabs(element = nil)
    wait_for { page }.to have_css('.MuiAppBar-root .NavBarContent__items')
    found = page.find('.MuiAppBar-root .NavBarContent__items')
    return found if element.nil?

    found.find(element)
  end

  def main_content(element = nil)
    found = page.find('#start-of-content')
    return found if element.nil?

    found.find(element)
  end

  def resource_selector(iri, element: 'div', child: nil, parent: page)
    selector = "#{element}[resource='#{iri}']"
    wait_for(parent).to have_css selector
    found = parent.find(selector)
    return found if child.nil?

    wait_for(found).to have_css child
    found.find(child)
  end
end
