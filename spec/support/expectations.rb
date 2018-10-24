# frozen_string_literal: true

module Expectations
  def expect_form(name)
    wait_for(page).to have_content name
    expect(page).to have_css 'form'
  end

  def expect_published_message(type)
    wait_for(page).to(
      have_content("#{type} published successfully. It can take a few moments before it's visible on other pages.")
    )
  end

  def expect_updated_message(type)
    wait_for(page).to(
      have_content("#{type} saved successfully")
    )
  end
end
