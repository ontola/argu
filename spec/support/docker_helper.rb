# frozen_string_literal: true

require 'docker-api'
require_relative '../../services'

module DockerHelper
  def docker_reset_databases
    db_managed_services.each do |db|
      docker_drop_database(db)
      docker_postgres_command('--command', "CREATE DATABASE #{db}_test;")
      docker_restore_dump(db)
    end
  end

  def docker_clean_database(db, times = 0)
    docker_postgres_command('-d', "#{db}_test", '--command', CLEAN_TABLES)
  rescue StandardError => e
    raise e if times >= 3

    puts "Retry to clean #{db}"
    docker_clean_database(db, times + 1)
  end

  def docker_reset_redis
    docker_exec('redis', ['redis-cli', 'FLUSHALL'])
  end

  def docker_restore_dump(db, times = 0)
    docker_postgres_command('-d', "#{db}_test", '-f', "/var/lib/postgresql/data/dump_#{db}")
  rescue StandardError => e
    raise e if times >= 3

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

  def docker_drop_database(database)
    docker_postgres_command('--command', "UPDATE pg_database SET datallowconn=false WHERE datname='#{database}_test';")

    docker_postgres_command(
      '--command',
      'SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '\
        "'#{database}_test' AND pid <> pg_backend_pid();"
    )

    docker_postgres_command('--command', "DROP DATABASE #{database}_test;")
  end

  def docker_container(name)
    container = Docker::Container.get("devproxy_#{name}_1")
    container if container.info['State']['Running']
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

    result = Timeout.timeout(120, Timeout::Error, "Execution of #{commands} expired for service #{service}") do
      container.exec(commands)
    end
    return result if result[-1] == 0

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

  def run_local(service, commands)
    path = File.expand_path("../#{SERVICES[service.to_sym][:path] || service}")
    system(
      "cd #{path}; "\
      "BUNDLE_GEMFILE=#{path}/Gemfile #{commands.join(' ').gsub('bundle exec ', "bundle exec #{path}/bin/")}"
    )
  end

  def var_from_rails_console(command)
    rails_runner(:argu, "Apartment::Tenant.switch('argu') { puts #{command} }")
      .first
      .first
      .split("\n")
      .last
  end

  def docker_postgres_command(*args)
    docker_exec('postgres', ['psql', '--username', 'postgres'] + args)
  end
end
