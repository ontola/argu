# frozen_string_literal: true
require 'logger'

module ExceptionHelper
  module_function
  LOGGER = Logger.new(STDOUT)

  def raise_catched_emails
    return unless @mailcatcher_expectation

    catched = mailcatcher_mailbox.messages(reload: true).map { |m| "#{m.to}: #{m.subject}" }.join("\n")
    catched.empty? ? raise('No emails catched') : raise("Catched emails:\n#{catched}")
  end

  def upload_container_logs(example)
    (DockerHelper::SERVICES.keys + %w[devproxy frontend sidekiq]).each do |service|
      ['', '_sidekiq', '_subscriber'].each do |suffix|
        container = "#{service}#{suffix}"
        if docker_container(container)
          upload_exception_file(docker_container(container).logs(stdout: true), example, "#{container}.log")
        end
      end
    end
  end

  def example_filename(example, suffix = nil)
    [example.full_description.tr(' ', '-'), suffix].compact.join('.')
  end

  def upload_browser_logs(example)
    upload_javascript_console_logs(example)
    upload_javascript_errors(example)
    upload_javascript_logs(example)
  end

  def upload_javascript_console_logs(example)
    errors = page.driver.browser.manage.logs.get(:browser)
    upload_exception_file(errors.map(&:message).join("\n"), example, 'javascript-console.log') if errors
  rescue StandardError => e
    LOGGER.error "Failed to show console logs: #{e.message}"
  end

  def upload_javascript_errors(example)
    errors = page.execute_script('return (window.logging && window.logging.errors)')
    return unless errors&.length&.positive?

    upload_exception_file(errors.join("\n"), example, 'javascript-errors.log')
  rescue StandardError => e
    LOGGER.error "Failed to show javascript errors: #{e.message}"
  end

  def upload_javascript_logs(example)
    logs = page.execute_script('return (window.logging && window.logging.logs)')
    upload_exception_file(logs.map { |message| message.join(' ') }.join("\n"), example, 'javascript-logs.log') if logs
  rescue StandardError => e
    LOGGER.error "Failed to show javascript logs: #{e.message}"
  end

  def upload_screenshot(name)
    exception_file_dir
    saver = Capybara::Screenshot.new_saver(Capybara, Capybara.page, false, name)
    saver.save
    upload_to_bitbucket(saver.screenshot_path)
  end

  def upload_to_bitbucket(path)
    return unless ENV['BITBUCKET_STORAGE']

    RestClient::Request.execute(
      method: :post,
      url: ENV['BITBUCKET_STORAGE'],
      user: ENV['BOT_USERNAME'],
      password: ENV['BOT_PASSWORD'],
      payload: {files: File.new(path)}
    )
  end

  private

  def upload_exception_file(content, example, suffix)
    filename = [exception_file_dir, example_filename(example, suffix)].join('/')
    File.open(filename, 'w') { |f| f.write(content) }

    Timeout::timeout(30) do
      upload_to_bitbucket(filename)
    end
  end

  def exception_file_dir
    return @exception_file_dir if @exception_file_dir

    dir = File.expand_path('../../tmp/exceptions', __dir__)
    FileUtils.mkdir_p dir
    @exception_file_dir = dir
  end
end
