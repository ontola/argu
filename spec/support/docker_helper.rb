# frozen_string_literal: true

require 'docker-api'
require 'redis'
require_relative '../../services'

module DockerHelper
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

  def cleanup_before_test
    docker_reset_databases
    docker_reset_redis
    mailcatcher_clear
  end

  def docker_reset_databases
    db_managed_services.each do |db|
      docker_clean_database(db)
      docker_restore_dump(db)
    end
  end

  def docker_clean_database(db, times = 0)
    docker_postgres_command('-d', "#{db}_test", '--command', CLEAN_TABLES)
  rescue StandardError => e
    raise e if times >= 3

    docker_close_connections(db)
    puts "Retry to clean #{db}"
    docker_clean_database(db, times + 1)
  end

  def docker_close_connections(db)
    docker_postgres_command(
      '--command',
      'SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '\
        "'#{db}_test' AND pid <> pg_backend_pid();"
    )
  end

  def docker_dump_redis
    puts 'Dumping database redis'
    docker_exec('redis', ['apt', 'update'])
    docker_exec('redis', ['apt', 'install', '-y', 'python3-pip'])
    docker_exec('redis', ['pip3', 'install', 'rdbtools', 'python-lzf'])
    docker_exec('redis', ['redis-cli', 'SAVE'])
    docker_exec('redis', ['rm', '-f', '/data/dump.protocol'])
    docker_exec('redis', ['rdb', '-c', 'protocol', '-f', '/data/dump.protocol', '/data/dump.rdb'])
  end

  def docker_reset_redis
    redis_libro_client.flushdb
    redis_cache_client.flushdb
    docker_exec('redis', ['sh', '-c', 'cat /data/dump.protocol | redis-cli --pipe'])
  end

  def docker_restore_dump(db, times = 0)
    docker_exec(
      'postgres',
      ['pg_restore', "/var/lib/postgresql/data/dump_#{db}", '-Fc', '--username=postgres', '--clean', '-d', "#{db}_test"]
    )
  rescue StandardError => e
    raise e if times >= 3

    docker_close_connections(db)
    docker_clean_database(db)
    puts "Retry to restore #{db}"
    docker_restore_dump(db, times + 1)
  end

  def docker_containers
    Docker::Container.all
  end

  def docker_container_name(container)
    container.json["Name"][1..]
  end

  def docker_container(name)
    docker_container_find("devproxy_#{name}_1") || docker_container_find("devproxy-#{name}-1")
  end

  def docker_container_find(name)
    container = Docker::Container.get(name)
    container if container.is_a?(Docker::Container) && container.info['State']['Running']
  rescue Docker::Error::NotFoundError
    nil
  end

  def docker_setup(container, seed: nil)
    docker_exec(container, %w[bundle exec rake db:create])
    docker_exec(container, %w[bundle exec rake db:schema:load])
    if seed
      docker_exec(container, ['bundle', 'exec', 'rake', "db:seed:single[#{seed}]"])
    else
      docker_exec(container, %w[bundle exec rake db:seed])
    end
  end

  def docker_exec(service, commands)
    container = docker_container(service)
    return run_local(service, commands) if container.nil?

    result = Timeout.timeout(180, Timeout::Error, "Execution of #{commands} expired for service #{service}") do
      container.exec(commands)
    end
    return result.first.first if result[-1] == 0

    result[0].each { |message| puts message }
    result[1].each { |message| puts message }
    raise "#{service} results in exit code #{result[2]}"
  end

  def db_managed_services
    SERVICES
      .filter { |_, v| v[:manage_db] != false }
      .map { |k, _| k }
  end

  def rails_runner(service, command)
    raise 'command may not include double quotes' if command.include?('"')
    docker_exec(service, ['bin/rails', 'runner', docker_container(service) ? command : "\"#{command}\""])
  end

  def redis_apex_client
    @redis_apex_client ||= Redis.new(url: ENV['REDIS_URL'], db: 0)
  end

  def redis_cache_client
    @redis_cache_client ||= Redis.new(url: ENV['REDIS_URL'], db: 8)
  end

  def redis_cache_persisted_client
    @redis_cache_persisted_client ||= Redis.new(url: ENV['REDIS_URL'], db: 6)
  end

  def redis_libro_client
    @redis_libro_client ||= Redis.new(url: ENV['REDIS_URL'], db: 0)
  end

  def run_local(service, commands)
    path = File.expand_path("../#{SERVICES[service.to_sym][:path] || service}")

    `cd #{path}; BUNDLE_GEMFILE=#{path}/Gemfile #{commands.join(' ').gsub('bundle exec ', "bundle exec #{path}/bin/")}`
  end

  def var_from_rails_console(command)
    rails_runner(:argu, "Apartment::Tenant.switch('argu') { puts #{command} }")
      .split("\n")
      .last
  end

  def docker_postgres_command(*args)
    docker_exec('postgres', ['psql', '--username', 'postgres'] + args)
  end
end
