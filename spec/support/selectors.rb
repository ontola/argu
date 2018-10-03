# frozen_string_literal: true

module Selectors
  def count_bubble_count(element = nil)
    wait_for(page).to have_css('.CountBubble__number')
    found = page.find('.CountBubble__number')
    return found if element.nil?
    found.find(element)
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
end
