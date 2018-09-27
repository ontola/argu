# frozen_string_literal: true

require 'docker-api'

module DockerHelper
  SERVICES = {
    argu: :argu,
    token: :token_service,
    email: :email_service
  }

  def docker_reset_databases
    SERVICES.keys.each { |db| docker_drop_database(db) }
    docker_postgres_command('-f', '/var/lib/postgresql/data/dump', 'postgres')
  end

  def docker_drop_database(database)
    docker_postgres_command('--command', "UPDATE pg_database SET datallowconn=false WHERE datname='#{database}_test';")

    docker_postgres_command(
      '--command',
      'SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '\
        "'#{database}_test' AND pid <> pg_backend_pid();"
    )

    docker_postgres_command('--command', "DROP DATABASE #{database}_test")
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

  def docker_run(container, commands)
    if docker_container(container).nil?
      path = File.expand_path("../#{SERVICES[container.to_sym]}")
      system(
        "cd #{path}; "\
        "BUNDLE_GEMFILE=#{path}/Gemfile #{commands.join(' ').gsub('bundle exec ', "bundle exec #{path}/bin/")}"
      )
    else
      result = docker_container(container).exec(commands)
      return result if result[-1] == 0
      result[0].each { |message| puts message }
      result[1].each { |message| puts message }
      raise "#{container} results in exit code #{result[2]}"
    end
  end

  def docker_postgres_command(*args)
    docker_run('postgres', ['psql', '--username', 'postgres'] + args)
  end
end