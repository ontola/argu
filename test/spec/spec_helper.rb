# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'capybara/rspec'
require 'capybara/playwright'
require 'dotenv'
require 'rspec/wait'
require 'rspec/instafail'
require 'rspec/retry'
require 'support/exception_helper'
require 'support/expectations'
require 'support/mailcatcher_helper'
require 'support/matchers'
require 'support/docker_helper'
require 'support/test_methods'
require 'support/requests_helper'
require 'support/selectors'

require_relative './support/slice_matchers'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

Playwright.define_channel_owner :Tracing
Dotenv.load

RSpec.configure do |config|
  include DockerHelper

  config.include RequestsHelper
  config.include ExceptionHelper
  config.include Expectations
  config.include MailCatcherHelper
  config.include Matchers
  config.include DockerHelper
  config.include TestMethods
  config.include Selectors
  config.include SliceMatchers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.wait_timeout = ENV['RSPEC_WAIT']&.to_i || 15

  config.verbose_retry = true
  config.around(:each) do |ex|
    ex.run_with_retry retry: 1
  end
  config.retry_callback = ->  { cleanup_before_test }

  config.before(:suite) do
    MANAGED_DATABASES.each do |service|
      puts "Checking #{service}"
      table_exists =
        docker_container('postgres')
          .exec(
            ['psql', '-tAc', "SELECT 1 FROM pg_database WHERE datname='#{service}_test'", '--username', 'postgres']
          )[0] == ["1\n"]
      raise "Database '#{service}_test' does not exist. Did you run `bundle exec rake test:setup`?" unless table_exists

      puts '- Database ready'
    end
    puts 'Services are ready'
  end

  config.before do |example|
    example.metadata[:start_time] = DateTime.now
    cleanup_before_test

    Capybara.current_session.driver.on_save_raw_screenshot_before_reset do |raw_screenshot|
      upload_html(example, page.html) if example.exception
      upload_screenshot(example, raw_screenshot) if example.exception
    end

    Capybara.current_session.driver.on_save_screenrecord do |video_path|
      upload_screenrecord(example, video_path) if example.exception
    end
  end

  config.after do |example|
    example.metadata[:end_time] = DateTime.now

    if example.exception
      puts 'Uploading exception details'
      upload_container_logs(example)
      upload_browser_logs(example)
      raise_catched_emails
    end
  end
end

Capybara.configure do |config|
  config.run_server = false
  config.default_driver = :playwright
  config.javascript_driver = :playwright
  config.app_host = 'https://argu.localtest'
end

Capybara.register_driver(:playwright) do |app|
  height = ENV['CI'] == 'true' ? 2000 : 768

  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium,
    playwright_cli_executable_path: 'npx playwright@1.23.4',
    headless: ENV['NO_HEADLESS'] ? false : true,
    chromiumSandbox: false,
    ignoreHTTPSErrors: true,
    viewport: {height: height, width: 1024},
    recordVideo: {
      size: {height: height, width: 1024}
    }
  )
end

Capybara.default_max_wait_time = 15

MailCatcher::API.configure do |config|
  config.server = 'http://mailcatcher:1080'
end

Capybara.save_path = File.expand_path('../tmp/exceptions', __dir__)
