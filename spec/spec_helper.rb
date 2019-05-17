# frozen_string_literal: true

require 'capybara/rspec'
require 'support/mock'
require 'selenium/webdriver'
require 'webdrivers'
require 'rspec/wait'
require 'support/exception_helper'
require 'support/expectations'
require 'support/mailcatcher_helper'
require 'support/matchers'
require 'support/docker_helper'
require 'support/test_methods'
require 'support/selectors'

module Selenium
  module WebDriver
    class Options
      # capybara/rspec installs a RSpec callback that runs after each test and resets
      # the session - part of which is deleting all cookies. However the call to Chrome
      # Webdriver to delete all cookies in Chrome 74 hangs when run in headless mode
      # (the reasons for which are still unknown).
      #
      # Fortunately, the call to set a cookie is still functioning and we can rely
      # on expired cookies being cleared by Chrome, so we iterate over all current
      # cookies and set their expiry date to some time in the past - effectively
      # deleting them.
      def delete_all_cookies
        all_cookies.each do |cookie|
          add_cookie(name: cookie[:name], value: '', expires: Time.now - 1.second)
        end
      end
    end
  end
end

RSpec.configure do |config|
  include DockerHelper

  config.include ExceptionHelper
  config.include Expectations
  config.include MailCatcherHelper
  config.include Matchers
  config.include DockerHelper
  config.include TestMethods
  config.include Selectors

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:suite) do
    DockerHelper::SERVICES.keys.each do |service|
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

  config.before do
    docker_reset_databases
    docker_reset_redis
    mailcatcher_clear
  end

  config.after do |example|
    if example.exception
      # upload_container_logs(example)
      # upload_javascript_logs(example)
      # raise_catched_emails
    end
  end
end

Capybara.configure do |config|
  config.run_server = false
  config.default_driver = :selenium_chrome
  config.app_host = 'https://app.argu.localtest'
end

Capybara.register_driver :selenium_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome('elementScrollBehavior' => 1)
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.open_timeout = 90
  client.read_timeout = 90
  options = Selenium::WebDriver::Chrome::Options.new
  options.headless!
  options.add_preference('intl.accept_languages', 'en-US')

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: options,
    http_client: client,
    desired_capabilities: capabilities
  )
end

MailCatcher::API.configure do |config|
  config.server = 'http://app.argu.localtest:1080'
end

# Capybara.save_path = File.expand_path('../tmp/exceptions', __dir__)
#
# Capybara::Screenshot.after_save_html do |path|
#   ExceptionHelper.upload_to_bitbucket(path)
# end
#
# Capybara::Screenshot.after_save_screenshot do |path|
#   ExceptionHelper.upload_to_bitbucket(path)
# end
#
# Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
#   ExceptionHelper.example_filename(example)
# end
# Capybara::Screenshot.append_timestamp = false
