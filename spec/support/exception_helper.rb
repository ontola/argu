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
    [example.full_description.tr(' ', '-'), suffix].compact.join('/').gsub('#', '-')
  end

  def upload_browser_logs(example)
    Timeout.timeout(60, Timeout::Error, 'Uploading browser logs timed out') do
      # TODO: upload_javascript_console_logs(example)
      upload_javascript_errors(example)
      upload_javascript_logs(example)
    end
  end

  def upload_javascript_console_logs(example)
    errors = page.driver.browser.manage.logs.get(:browser)
    upload_exception_file(errors.map(&:message).join("\n"), example, 'javascript-console.txt') if errors
  rescue StandardError => e
    LOGGER.error "Failed to show console logs: #{e.message}"
  end

  def upload_javascript_errors(example)
    errors = page.driver.evaluate_script('(window.logging && window.logging.errors)')
    return unless errors&.length&.positive?

    upload_exception_file(errors.map { |message| JSON.pretty_generate(message) }.join("\n"), example, 'javascript-errors.txt')
  rescue StandardError => e
    LOGGER.error "Failed to show javascript errors: #{e.message}"
  end

  def upload_javascript_logs(example)
    logs = page.driver.evaluate_script('(window.logging && window.logging.logs)')
    upload_exception_file(logs.map { |message| message.join(' ') }.join("\n"), example, 'javascript-logs.txt') if logs
  rescue StandardError => e
    LOGGER.error "Failed to show javascript logs: #{e.message}"
  end

  def upload_screenshot(example, raw_screenshot)
    upload_exception_file(raw_screenshot, example, 'screenshot.png')
  end

  def upload_screenrecord(example, video_path)
    suffix = video_path.split('/').last

    filename = name_for_file(example, suffix)
    ensure_exception_dir(filename)
    FileUtils.mv(video_path, filename)
  end

  private

  def name_for_file(example, suffix)
    [exception_file_dir, example_filename(example, suffix)].join('/')
  end

  def ensure_exception_dir(filename)
    FileUtils.mkdir_p(filename.split('/')[0...-1].join('/'))
  end

  def upload_exception_file(content, example, suffix)
    filename = name_for_file(example, suffix)
    ensure_exception_dir(filename)
    File.open(filename, 'w', encoding: 'ascii-8bit') { |f| f.write(content) }
  end

  def exception_file_dir
    return @exception_file_dir if @exception_file_dir

    dir = File.expand_path('../../tmp/exceptions', __dir__)
    FileUtils.mkdir_p dir
    @exception_file_dir = dir
  end
end
