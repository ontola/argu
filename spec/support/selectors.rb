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

  def navbar(element = nil)
    found = page.find('.Navbar')
    return found if element.nil?

    found.find(element)
  end

  def navbar_tabs(element = nil)
    wait_for { page }.to have_css('.Navbar .NavBarContent__items')
    found = page.find('.Navbar .NavBarContent__items')
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
