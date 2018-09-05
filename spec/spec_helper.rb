# frozen_string_literal: true

require 'capybara/rspec'
require 'support/mock'
require 'selenium/webdriver'
require 'rspec/wait'
require 'support/mailcatcher_helper'
require 'support/docker_helper'
require 'support/test_methods'
require 'support/selectors'

RSpec.configure do |config|
  include DockerHelper

  config.include MailCatcherHelper
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
    DockerHelper::SERVICES.each do |service|
      puts "Checking #{service}"
      unless docker_container(service) && docker_container(service).info['State']['Running']
        raise "Container '#{service}' is not found. Did you run `./test.sh`?"
      end
      puts "- Container ready"
      unless docker_container('postgres').exec(['psql', "#{service}_test", '--username', 'postgres'])[2] == 0
        raise "Database '#{service}' does not exist. Did you run `bundle exec rake test:setup`?"
      end
      puts "- Database ready"
    end
    puts 'Services are ready'
  end

  config.before(:each) do
    docker_reset_databases
    mailcatcher_clear
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
  client.timeout = 90
  options = Selenium::WebDriver::Chrome::Options.new
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
