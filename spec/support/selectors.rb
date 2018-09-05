# frozen_string_literal: true

module Selectors
  def sidebar(element = nil)
    found = page.find('.NavBarContent')
    return found if element.nil?
    found.find(element)
  end

  def main_content(element = nil)
    found = page.find('#start-of-content')
    return found if element.nil?
    found.find(element)
  end
end
