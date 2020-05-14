# frozen_string_literal: true

require 'docker-api'

module DockerHelper
  SERVICES = {
    argu: :argu,
    token: :token_service,
    email: :email_service
  }.freeze
  CLEAN_TABLES = <<END_HEREDOC
DO
$func$
BEGIN
  EXECUTE
  (SELECT 'TRUNCATE TABLE '
    || string_agg(quote_ident(schemaname) || '.' || quote_ident(tablename), ', ')
    || ' CASCADE'
   FROM pg_tables
   WHERE schemaname IN ('public', 'argu')
  );
END
$func$;
END_HEREDOC

  def docker_reset_databases
    SERVICES.keys.each do |db|
      docker_clean_database(db)
      docker_run(
        'postgres',
        ['pg_restore', "/var/lib/postgresql/data/dump_#{db}", '-Fc', '--username=postgres', '--clean', '-d', "#{db}_test"]
      )
    end
  end

  def docker_clean_database(db, times = 0)
    docker_postgres_command('-d', "#{db}_test", '--command', CLEAN_TABLES)
  rescue
    docker_clear_database(db, times + 1) unless times >= 3
  end

  def docker_reset_redis
    docker_run('redis', ['redis-cli', 'FLUSHALL'])
  end

  def docker_container(name)
    container = Docker::Container.get("devproxy_#{name}_1")
    container if container.info['State']['Running']
  rescue Docker::Error::NotFoundError
    nil
  end

  def docker_setup(container, seed: nil)
    docker_run(container, %w[bundle exec rake db:create])
    docker_run(container, %w[bundle exec rake db:schema:load])
    if seed
      docker_run(container, ['bundle', 'exec', 'rake', "db:seed:single[#{seed}]"])
    else
      docker_run(container, %w[bundle exec rake db:seed])
    end
  end

  def docker_run(service, commands)
    container = docker_container(service)
    return run_local(service, commands) if container.nil?

    result = container.exec(commands)
    return result if result[-1] == 0

    result[0].each { |message| puts message }
    result[1].each { |message| puts message }
    raise "#{service} results in exit code #{result[2]}"
  end

  def rails_runner(service, command)
    raise 'command may not include double quotes' if command.include?('"')
    docker_run(service, ['bin/rails', 'runner', docker_container(service) ? command : "\"#{command}\""])
  end

  def run_local(service, commands)
    path = File.expand_path("../#{SERVICES[service.to_sym]}")
    system(
      "cd #{path}; "\
      "BUNDLE_GEMFILE=#{path}/Gemfile #{commands.join(' ').gsub('bundle exec ', "bundle exec #{path}/bin/")}"
    )
  end

  def docker_postgres_command(*args)
    docker_run('postgres', ['psql', '--username', 'postgres'] + args)
  end
end
