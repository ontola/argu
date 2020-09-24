# frozen_string_literal: true

require 'rspec/core/rake_task'
require_relative 'spec/support/docker_helper'
require_relative 'services'

RSpec::Core::RakeTask.new(:spec)

def check_env
  link = File.readlink(File.expand_path('.env'))
  raise "Trying to reset data in wrong env (expected test but got '#{link}')" unless link.end_with?('test')
end

namespace :test do
  desc 'Setup for running tests'
  task :setup do
    include DockerHelper
    check_env

    puts 'setting up argu'
    docker_setup('argu', seed: :test)
    puts 'setting up token'
    docker_setup('token', seed: :test)
    puts 'setting up email'
    docker_setup('email', seed: :test)

    puts 'dumping databases'
    db_managed_services.each do |db|
      docker_exec(
        'postgres',
        ['pg_dump', "#{db}_test", '--username=postgres', '-Fc', '--data-only', "--file=/var/lib/postgresql/data/dump_#{db}"]
      )
    end
  end

  task :reset do
    include DockerHelper
    check_env

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
    docker_setup('email')
  end
end
