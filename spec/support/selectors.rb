# frozen_string_literal: true

module Selectors
  def count_bubble_count(element = nil)
    wait_for(page).to have_css('.CountBubble__number')
    found = page.find('.CountBubble__number')
    return found if element.nil?

    found.find(element)
  end

  def current_user_section(*args)
    wait_for(page).to have_css "div[resource=\"#{current_tenant}/c_a\"]"
    found = page.find(".NavBarContent__footer div[resource=\"#{current_tenant}/c_a\"]")
    return found if args.empty?

    found.find(*args)
  end

  def sidebar(element = nil)
    found = page.find('.NavBarContent')
    return found if element.nil?

    found.find(element)
  end

  def sidebar_top(element = nil)
    found = page.find('.NavBarContent__top')
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

    found.find(child)
  end
end
