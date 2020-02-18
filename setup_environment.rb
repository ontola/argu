#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

raise 'No ENV given' if ENV['ENV'].empty?

puts "SETUP FOR #{ENV['ENV']}"

local_ports =
  if File.file?(File.expand_path('local_ports.yml', __dir__))
    YAML.load_file(File.expand_path('local_ports.yml')) || {}
  else
    {}
  end
services = {
  frontend: {
    image: 'eu.gcr.io/active-gasket-113610/aod_demo',
    command: 'node --use-openssl-ca ./dist/private/server.js',
    port: 8080
  },
  argu: {
    image: 'registry.gitlab.com/ontola/apex'
  },
  email: {},
  token: {
    image: 'registry.gitlab.com/ontola/token_service'
  },
  vote_compare: {},
  deku: {
    image: 'eu.gcr.io/active-gasket-113610/deku'
  }
}

# Create symlink to .env
File.delete(File.expand_path('.env', __dir__)) if File.symlink?(File.expand_path('.env', __dir__))
File.symlink(File.expand_path("../.env.#{ENV['ENV']}", __FILE__), File.expand_path('.env', __dir__))

# Create nginx.conf
File.open(File.expand_path('nginx.template.conf')) do |source_file|
  contents = source_file.read
  contents.gsub!(/\{your_local_ip\}/, ENV['IP'])
  services.each do |service, opts|
    location =
      if local_ports.key?(service.to_s)
        "#{ENV['IP']}:#{local_ports[service.to_s]}"
      else
        "#{service}.svc.cluster.local:#{opts[:port] || 2999}"
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
      local_ports.keys.map { |service| "- #{service}.svc.cluster.local" }.join("\n          ")
    end
  contents.gsub!(/\{devproxy_aliases\}/, devproxy_aliases)
  # Set external to true for test env
  contents.gsub!(/\$\{RESTRICT_EXTERNAL_NETWORK:-true\}/, ENV['ENV'] == 'test' ? 'true' : 'false')
  # set webservices
  webservices = services.reject { |service, _opts| local_ports.key?(service.to_s) }.map do |service, opts|
    image = opts[:image] || "eu.gcr.io/active-gasket-113610/#{service}_service"
    command = opts[:command] || './bin/rails server -b 0.0.0.0 -p 2999'
    health_check =
      if service === :argu
        <<END_HEREDOC
healthcheck:
      test: "curl -H 'Host: argu.localtest' -f http://localhost:2999/argu/d/health"
END_HEREDOC
      end

    <<END_HEREDOC
  #{service}:
    image: #{image}:${RAILS_ENV:-staging}
    env_file:
      - ${ENV_FILE:-./.env}
    volumes:
      - ./devproxyCA/cacert.pem:/etc/ssl/certs/cacert.pem
    command: #{command}
    depends_on:
      - redis
      - postgres
      - rabbitmq
      - elastic
    expose:
      - 2999
      - 9200
    networks:
      default:
        aliases:
          - #{service}.svc.cluster.local
    extra_hosts:
      - "elastic:#{ENV['HOST_IP'] || ENV['IP']}"
    #{health_check}
END_HEREDOC
  end.join
  contents.gsub!(/\{webservices\}/, webservices)

  # set testrunner
  testrunner = ''
  if ENV['TESTRUNNER']
    testrunner = <<END_HEREDOC
  testrunner:
    privileged: true
    build:
      context: .
      dockerfile: dockerfiles/testrunner.Dockerfile
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /dev/shm:/dev/shm
    networks:
      default:
      external:
END_HEREDOC
  end
  contents.gsub!(/\{testrunner\}/, testrunner)

  # Write to docker-compose file
  File.open(File.expand_path('docker-compose.yml'), 'w+') { |f| f.write(contents) }
end
