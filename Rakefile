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
    env =
      docker_container('argu').info['Config']['Env'].detect { |env| env.start_with?('FE_BUNDLE_NAME') }.split('=').last
    raise "Trying to load test data in #{env} env" unless env == 'localtest'
    docker_setup('argu', seed: :test)
    docker_setup('token_service', seed: :test)
    docker_run('email_service', %w[bundle exec rake db:setup])
    docker_run('vote_compare_service', %w[bundle exec rake db:setup])

    docker_run('postgres', %w[pg_dumpall --username=postgres --file=/var/lib/postgresql/data/dump])
  end
end

namespace :dev do
  desc 'Setup for development'
  task :setup do
    include DockerHelper
    docker_setup('argu')
    docker_setup('token_service')
    docker_run('email_service', %w[bundle exec rake db:setup])
    docker_run('vote_compare_service', %w[bundle exec rake db:setup])
  end
end
