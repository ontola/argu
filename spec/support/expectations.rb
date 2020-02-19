# frozen_string_literal: true

module Expectations
  def expect_form(action)
    wait_for { page }.to have_css "form[action='#{action}']"
  end

  def expect_draft_message(type)
    wait_for { page }.to(
      have_snackbar("#{type} created successfully. It will only be visible for others after you publish it.")
    )
  end

  def expect_published_message(type)
    wait_for { page }.to(
      have_snackbar("#{type} published successfully. It can take a few moments before it's visible on other pages.")
    )
  end

  def expect_updated_message(type)
    wait_for { page }.to(
      have_snackbar("#{type} saved successfully")
    )
  end
end
