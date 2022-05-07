# frozen_string_literal: true

require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'dotenv'
require 'selenium/webdriver'
require 'webdrivers'
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

require_relative '../services'
require_relative './support/slice_matchers'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

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
  config.exceptions_to_retry = [Selenium::WebDriver::Error::StaleElementReferenceError]

  config.before(:suite) do
    db_managed_services.each do |service|
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
    cleanup_before_test
  end

  config.after do |example|
    if example.exception
      upload_container_logs(example)
      upload_browser_logs(example)
      raise_catched_emails
    end
  end
end

Capybara.configure do |config|
  config.run_server = false
  config.default_driver = :selenium_chrome
  config.app_host = 'https://argu.localtest'
end

Capybara.register_driver :selenium_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    'elementScrollBehavior' => 1,
    'goog:loggingPrefs' => {browser: 'ALL'},
    loggingPrefs: {
      browser: 'ALL'
    },
    chromeOptions: {w3c: false}
  )

  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = 90
  client.open_timeout = 90
  options = Selenium::WebDriver::Chrome::Options.new
  options.headless! unless ENV['NO_HEADLESS']
  options.add_argument('--window-size=1920,1080')
  options.add_argument('--enable-logging')
  options.add_argument('--disable-gpu')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-extensions')
  options.add_argument('--disable-popup-blocking')
  options.add_argument('--no-sandbox')
  options.add_preference('intl.accept_languages', 'en-US')
  options.add_option('w3c', false)

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: options,
    http_client: client,
    desired_capabilities: capabilities
  )
end

MailCatcher::API.configure do |config|
  config.server = 'http://mailcatcher:1080'
end

Capybara.save_path = File.expand_path('../tmp/exceptions', __dir__)

Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  ExceptionHelper.example_filename(example)
end
Capybara::Screenshot.append_timestamp = false

module CapybaraNodeFix
  private

  def synced_resolve(*args)
    super
  rescue Capybara::ElementNotFound
    sleep 1
    super
  end
end

Capybara::Node::Base.prepend CapybaraNodeFix

module CapybaraExecuteFix
  def execute(*args)
    super
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    sleep 1
    super
  end
end

Selenium::WebDriver::Remote::OSS::Bridge.prepend CapybaraExecuteFix

module WaitFix
  def with_wait(*args)
    super
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    sleep 1
    super
  end
end

RSpec::Wait::Target.prepend WaitFix
