#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require_relative 'services'
require_relative 'compose_creator'

raise 'No ENV given' if ENV['ENV'].empty?

puts "SETUP FOR #{ENV['ENV']}"

local_ports =
  if File.file?(File.expand_path('local_ports.yml', __dir__))
    YAML.load_file(File.expand_path('local_ports.yml')) || {}
  else
    {}
  end

def env_keys(file)
  File.read(File.expand_path(file, __dir__))
    .split("\n")
    .map { |l| l.index('#').nil? ? l : l[l.index('#')..-1] }
    .map(&:strip)
    .select(&:presence)
    .map { |l| l.split("=").first }
end

# Create symlink to .env
File.delete(File.expand_path('.env', __dir__)) if File.symlink?(File.expand_path('.env', __dir__))
File.symlink(File.expand_path("../.env.#{ENV['ENV']}", __FILE__), File.expand_path('.env', __dir__))

template_keys = env_keys('.env.template')
actual_keys = env_keys('.env')
all_keys_present = (template_keys & actual_keys).length == template_keys.length

unless all_keys_present
  puts "Warning! Missing environment variables present in template: #{template_keys - actual_keys}"
end

# Create nginx.conf
File.open(File.expand_path('nginx.template.conf')) do |source_file|
  contents = source_file.read
  contents.gsub!(/\{your_local_ip\}/, ENV['IP'])
  SERVICES.each do |service, opts|
    location =
      if local_ports.key?(service.to_s)
        "#{ENV['IP']}:#{local_ports[service.to_s]}"
      else
        "#{service.to_s.dasherize}.svc.cluster.local:#{opts[:port] || 2999}"
      end
    contents.gsub!(/\{#{service}_host\}/, location)
  end
  File.open(File.expand_path('nginx.conf'), 'w+') { |f| f.write(contents) }
end

# Create docker-compose.yml
File.open(File.expand_path('docker-compose.template.yml')) do |source_file|
  contents = source_file.read
  # Set aliases for services run locally to the devproxy, so it can route the internal requests to the host machine
  devproxy_aliases =
    if local_ports.empty?
      '- none'
    else
      local_ports.keys.map { |service| "- #{service.to_s.dasherize}.svc.cluster.local" }.join("\n          ")
    end
  contents.gsub!(/\{devproxy_aliases\}/, devproxy_aliases)
  # Set external to true for test env
  contents.gsub!(/\$\{RESTRICT_EXTERNAL_NETWORK:-true\}/, ENV['ENV'] == 'test' ? 'true' : 'false')
  # set webservices
  webservices = SERVICES
                  .reject { |service, _opts| local_ports.key?(service.to_s) }
                  .map { |service, opts| ComposeCreator.service_entry(service, opts) }
                  .join
  contents.gsub!(/\{webservices\}/, webservices)

  contents.gsub!(/\{testrunner\}/, ComposeCreator.testrunner_entry)

  # Write to docker-compose file
  File.open(File.expand_path('docker-compose.yml'), 'w+') { |f| f.write(contents) }
end


