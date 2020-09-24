# frozen_string_literal: true

module ComposeCreator
  def service_entry(name, opts)
    service_entry_item(name, opts)

    setup_service = opts[:setup] ? service_entry_item("#{name}_setup", opts.merge(opts[:setup])) : ''
    opts[:depends_on] = opts[:setup] ? "#{name}_setup" : nil

    [service_entry_item(name, opts), setup_service].join
  end

  def service_entry_item(name, opts)
    image = opts[:image] || "registry.gitlab.com/ontola/#{name}_service"
    command = opts[:command] || './bin/rails server -b 0.0.0.0 -p 2999'

    <<END_HEREDOC
  #{name}:
    image: #{image}:${RAILS_ENV:-staging}
    env_file:
      - ${ENV_FILE:-./.env}
  #{env_entry(opts[:env])}
    volumes:
      - ./devproxyCA/cacert.pem:/etc/ssl/certs/cacert.pem
    command: #{command}
    depends_on:#{depends_on(opts[:depends_on])}
      - redis
      - postgres
      - rabbitmq
      - elastic
    expose:#{port(opts[:port])}
      - 2999
      - 9200
    networks:
      default:
        aliases:
          - #{name}.svc.cluster.local
    extra_hosts:
      - "elastic:#{ENV['HOST_IP'] || ENV['IP']}"
#{health_entry(opts[:health])}
END_HEREDOC
  end

  def depends_on(depends_on)
    "\n      - #{depends_on}" if depends_on
  end

  def env_entry(env)
    return unless env

    entries = env.entries.map { |key, value| "#{key}: \"#{value}\"" }.join("\n      ")
    "  environment:\n      #{entries}"
  end

  def health_entry(health)
    "    healthcheck:\n      test: \"#{health}\"\n" if health
  end

  def port(port)
    "\n      - #{port}" if port
  end

  def testrunner_entry
    return '' unless ENV['TESTRUNNER']

    <<END_HEREDOC

  testrunner:
    privileged: true
    build:
      context: .
      dockerfile: dockerfiles/testrunner.Dockerfile
      cache_from:
        - registry.gitlab.com/ontola/core:latest
    image: registry.gitlab.com/ontola/core:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /dev/shm:/dev/shm
    networks:
      default:
      external:
END_HEREDOC
  end
end
