#!/usr/bin/env ruby

require 'yaml'

raise 'No ENV given' unless ENV['ENV'].length > 0
puts "SETUP FOR #{ENV['ENV']}"

local_ports =
  if File.file?(File.expand_path('../local_ports.yml', __FILE__))
    YAML.load_file(File.expand_path('local_ports.yml')) || {}
  else
    {}
  end
services = {
  frontend: {
    image: 'aod_demo',
    command: 'node --use-openssl-ca ./dist/private/server.js',
    port: 8080
  },
  argu: {
    image: 'argu',
  },
  email: {},
  token: {},
  vote_compare: {},
  deku: {
    image: 'deku'
  }
}

# Create symlink to .env
File.delete(File.expand_path('../.env', __FILE__)) if File.symlink?(File.expand_path('../.env', __FILE__))
File.symlink(File.expand_path("../.env.#{ENV['ENV']}", __FILE__), File.expand_path('../.env', __FILE__))

# Create nginx.conf
File.open(File.expand_path('nginx.conf.template')) do |source_file|
  contents = source_file.read
  contents.gsub!(%r{\{your_local_ip\}}, ENV['IP'])
  services.each do |service, opts|
    location =
      if local_ports.key?(service.to_s)
        "#{ENV['IP']}:#{local_ports[service.to_s]}"
      else
        "#{service}.svc.cluster.local:#{opts[:port] || 2999}"
      end
    contents.gsub!(%r{\{#{service}_host\}}, location)
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
  contents.gsub!(%r{\{devproxy_aliases\}}, devproxy_aliases)
  # Set external to true for test env
  contents.gsub!(%r{\$\{RESTRICT_EXTERNAL_NETWORK:-true\}}, ENV['ENV'] == 'test' ? 'true' : 'false')
  # set webservices
  webservices = services.reject { |service, _opts| local_ports.key?(service.to_s) }.map do |service, opts|
    image = opts[:image] || "#{service}_service"
    command = opts[:command] || './bin/rails server -b 0.0.0.0 -p 2999'
    <<END_HEREDOC
  #{service}:
    image: eu.gcr.io/active-gasket-113610/#{image}:${RAILS_ENV:-staging}
    env_file:
      - ${ENV_FILE:-./.env}
    volumes:
      - ./devproxyCA/cacert.pem:/etc/ssl/certs/cacert.pem
    command: #{command}
    expose:
      - 2999
    networks:
      default:
        aliases:
          - #{service}.svc.cluster.local
END_HEREDOC
  end.join
  contents.gsub!(%r{\{webservices\}}, webservices)

  # Write to docker-compose file
  File.open(File.expand_path('docker-compose.yml'), 'w+') { |f| f.write(contents) }
end