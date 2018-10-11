# frozen_string_literal: true

require 'rspec/core/rake_task'
require_relative 'spec/support/mock'
require_relative 'spec/support/docker_helper'

RSpec::Core::RakeTask.new(:spec)

namespace :test do
  desc 'Setup for running tests'
  task :setup do
    include DockerHelper
    Mock.new.nominatim
    raise "Trying to load test data in #{env} env" unless File.readlink(File.expand_path('.env')).end_with?('test')

    docker_setup('argu', seed: :test)
    docker_setup('token', seed: :test)
    docker_run('email', %w[bundle exec rake db:setup])
    docker_run('vote_compare', %w[bundle exec rake db:setup])

    docker_run('postgres', %w[pg_dumpall --username=postgres --file=/var/lib/postgresql/data/dump])
  end

  task :reset do
    include DockerHelper
    docker_reset_databases
    docker_reset_redis
  end
end

namespace :dev do
  desc 'Setup for development'
  task :setup do
    include DockerHelper
    docker_setup('argu')
    docker_setup('token')
    docker_run('email', %w[bundle exec rake db:setup])
    docker_run('vote_compare', %w[bundle exec rake db:setup])
  end
end
