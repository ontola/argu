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
    raise 'Trying to reset data in wrong env' unless File.readlink(File.expand_path('.env')).end_with?('test')

    docker_setup('argu', seed: :test)
    docker_setup('token', seed: :test)
    docker_setup('email')
    docker_setup('deku')
    docker_setup('vote_compare')

    SERVICES.keys.each do |db|
      docker_run(
        'postgres',
        ['pg_dump', "#{db}_test", '--username=postgres', "--file=/var/lib/postgresql/data/dump_#{db}"]
      )
    end
  end

  task :reset do
    include DockerHelper
    raise 'Trying to reset data in wrong env' unless File.readlink(File.expand_path('.env')).end_with?('test')

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
    docker_setup('deku')
    docker_setup('vote_compare')
  end
end
