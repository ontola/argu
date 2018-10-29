# frozen_string_literal: true

module ExceptionHelper
  module_function

  def raise_catched_emails
    return unless @mailcatcher_expectation

    catched = mailcatcher_mailbox.messages(reload: true).map { |m| "#{m.to}: #{m.subject}" }.join("\n")
    catched.empty? ? raise('No emails catched') : raise("Catched emails:\n#{catched}")
  end

  def upload_container_logs(example)
    (DockerHelper::SERVICES.keys + %w[devproxy frontend]).each do |container|
      if docker_container(container)
        upload_exception_file(docker_container(container).logs(stdout: true), example, "#{container}.log")
      end
    end
  end

  def example_filename(example, suffix = nil)
    [example.full_description.tr(' ', '-'), suffix].compact.join('.')
  end

  def upload_javascript_logs(example)
    errors = page.driver.browser.manage.logs.get(:browser)
    upload_exception_file(errors.map(&:message).join("\n"), example, 'javascript.log') if errors
    status = page.evaluate_script(
      'typeof LRS !== \'undefined\' &&'\
      'JSON.stringify(Array.from(LRS.api.statusMap).reduce((obj, [key, value]) => ('\
      'Object.assign(obj, { [key.value]: value })), {}));'
    )
    upload_exception_file(JSON.pretty_generate(JSON.parse(status)), example, 'javascript.statements.log') if status
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

    upload_to_bitbucket(filename)
  end

  def exception_file_dir
    return @exception_file_dir if @exception_file_dir

    dir = File.expand_path('../../tmp/exceptions', __dir__)
    FileUtils.mkdir_p dir
    @exception_file_dir = dir
  end
end
