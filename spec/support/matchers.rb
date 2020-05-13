# frozen_string_literal: true

module Matchers
  RSpec::Matchers.define :have_snackbar do |expected|
    match do |actual|
      @actual =
        actual.execute_script('return window.logging.logs')
          .select(&method(:is_snackbar_action?))
          .map(&method(:action_log_snackbar_message))

      @actual.include?(expected)
    end

    diffable
  end

  def is_snackbar_action?(log)
    log.is_a?(Array) &&
      log.first == 'Link action:' &&
      action_log_iri(log)&.start_with?('https://ns.ontola.io/libro/actions/snackbar')
  end

  def action_log_snackbar_message(log)
    CGI.parse(action_log_iri(log).split('?').pop)['text'][0]
  end

  def action_log_iri(log)
    log[1]['value']
  end
end
