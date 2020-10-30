# frozen_string_literal: true
require 'logger'

require_relative '../../services'

module ExceptionHelper
  module_function
  LOGGER = Logger.new(STDOUT)

  def raise_catched_emails
    return unless @mailcatcher_expectation

    catched = mailcatcher_mailbox.messages(reload: true).map { |m| "#{m.to}: #{m.subject}" }.join("\n")
    catched.empty? ? raise('No emails catched') : raise("Catched emails:\n#{catched}")
  end

  def upload_container_logs(example)
    docker_containers.each do |container|
        upload_exception_file(
          container.logs(stdout: true, stderr: true),
          example,
          "#{docker_container_name(container)}_#{container.id}.txt"
        )
    end
  end

  def example_filename(example, suffix = nil)
    [example.full_description.tr(' ', '-'), suffix].compact.join('/')
  end

  def upload_browser_logs(example)
    upload_javascript_console_logs(example)
    upload_javascript_errors(example)
    upload_javascript_logs(example)
  end

  def upload_javascript_console_logs(example)
    errors = page.driver.browser.manage.logs.get(:browser)
    upload_exception_file(errors.map(&:message).join("\n"), example, 'javascript-console.txt') if errors
  rescue StandardError => e
    LOGGER.error "Failed to show console logs: #{e.message}"
  end

  def upload_javascript_errors(example)
    errors = page.execute_script('return (window.logging && window.logging.errors)')
    return unless errors&.length&.positive?

    upload_exception_file(errors.map { |message| JSON.pretty_generate(message) }.join("\n"), example, 'javascript-errors.txt')
  rescue StandardError => e
    LOGGER.error "Failed to show javascript errors: #{e.message}"
  end

  def upload_javascript_logs(example)
    logs = page.execute_script('return (window.logging && window.logging.logs)')
    upload_exception_file(logs.map { |message| message.join(' ') }.join("\n"), example, 'javascript-logs.txt') if logs
  rescue StandardError => e
    LOGGER.error "Failed to show javascript logs: #{e.message}"
  end

  def upload_screenshot(name)
    exception_file_dir
    saver = Capybara::Screenshot.new_saver(Capybara, Capybara.page, false, name)
    saver.save
  end

  private

  def upload_exception_file(content, example, suffix)
    filename = [exception_file_dir, example_filename(example, suffix)].join('/')
    FileUtils.mkdir_p(filename.split('/')[0...-1].join('/'))
    File.open(filename, 'w') { |f| f.write(content) }
  end

  def exception_file_dir
    return @exception_file_dir if @exception_file_dir

    dir = File.expand_path('../../tmp/exceptions', __dir__)
    FileUtils.mkdir_p dir
    @exception_file_dir = dir
  end
end
