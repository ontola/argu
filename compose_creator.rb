# frozen_string_literal: true

module ComposeCreator
  SERVICE_INDENTATION = ' ' * 2

  class << self
    def service_entry(name, opts)
      opts = opts.with_indifferent_access
      opts[:name] = name
      opts[:image] = opts[:image] || "registry.gitlab.com/ontola/#{name}_service"
      opts[:image] = "#{opts[:image]}:${RAILS_ENV:-staging}"

      setup_service =
        if opts[:setup]
          setup_opts = opts
                         .merge(setup_template(opts))
                         .merge({name: "#{name}_setup"})
                         .merge(opts[:setup])
          service_entry_item(setup_opts)
        end
      opts[:depends_on] = opts[:setup] ? "#{name}_setup" : nil

      base_opts = opts.merge(base_service_template(opts))
      base_opts[:ports] = ["#{opts[:port]}:#{opts[:port]}"] if opts[:port]
      service_base = service_entry_item(base_opts)
      derivative_opts = derivative_opts_filter(opts)
      subscriber_service =
        if opts[:subscriber]
          subscriber_opts = derivative_opts
                              .merge(subscriber_template_opts(derivative_opts))
                              .merge(name: "#{name}_subscriber")
                              .merge(derivative_opts[:subscriber])
          service_entry_item(subscriber_opts)
        end
      worker_service =
        if opts[:worker]
          worker_opts = derivative_opts
                   .merge(worker_template_opts(derivative_opts))
                   .merge(name: "#{name}_worker")
                   .merge(derivative_opts[:worker])
          service_entry_item(worker_opts)
        end

      [service_base, setup_service, worker_service, subscriber_service].compact.join
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

    private

    def service_entry_item(opts)
      template = base_template(opts)
      overrides = {
        'command' => opts[:command] || template[:command],
        'depends_on' => (template['depends_on'] || [])
                          .concat([opts[:depends_on]])
                          .flatten
                          .compact
                          .presence,
        'ports' => opts[:ports],
        'expose' => opts[:port],
        'extra_hosts' => [
          "elastic:#{ENV['HOST_IP'] || ENV['IP']}"
        ],
        'restart' => opts[:restart]
      }

      entry = {
        opts[:name] => template
                         .merge(overrides)
                         .compact
      }

      entry
        .deep_stringify_keys
        .to_hash
        .to_yaml
        .sub(/^---\n/, '')
        .sub(/"\$\{ENV_FILE:-\.\/\.env\}"/, '${ENV_FILE:-./.env}')
        .gsub(/^/, SERVICE_INDENTATION)
    end

    def base_template(opts)
      {
        'image' => opts[:image],
        'env_file' => [
          '${ENV_FILE:-./.env}'
        ],
        'networks' => opts['networks'],
        'volumes' => [
          "./devproxyCA/cacert.pem:/etc/ssl/certs/cacert.pem"
        ].concat(opts[:volumes] || [])
      }.merge(health_entry(opts[:health]))
        .merge(env_entry(opts[:env]))
    end

    def base_service_template(opts)
      {
        'command' => opts[:command] || './bin/rails server -b 0.0.0.0 -p 2999',
        'depends_on' => %w[
          redis
          rabbitmq
          elastic
        ],
        'port' => port(opts[:port]),
        'networks' => {
          'default' => {
            'aliases' => [
              "#{opts[:name].to_s.dasherize}.svc.cluster.local"
            ]
          },
        }
      }
    end

    def setup_template(opts)
      base_service_template(opts)
        .merge('depends_on' => nil, 'networks' => nil)
    end

    def derivative_opts_filter(opts)
      opts.merge(
        'depends_on' => nil,
        'port' => nil,
        'expose' => nil,
        'health' => nil,
        'networks' => nil,
      )
    end

    def subscriber_template_opts(opts)
      base_template(opts).merge(
        'restart' => 'unless-stopped',
        'volumes' => ['certdata:/etc/ssl/certs']
      )
    end

    def worker_template_opts(opts)
      base_template(opts).merge(
        'volumes' => ['certdata:/etc/ssl/certs']
      )
    end

    def env_entry(env)
      return {} unless env

      {
        "environment" => env.to_hash
      }
    end

    def health_entry(health)
      return {} unless health

      {
        'healthcheck' => {
          'test' => health
        }
      }
    end

    def worker_entry(opts)
      return "" unless opts[:worker]

      "  #{opts[:name]}_worker  "
    end

    def subscriber_entry(opts)
      return "" unless opts[:subscriber]

      "  #{opts[:name]}_subscriber  "
    end

    def port(port)
      [2999, 9200, port].compact
    end
  end
end
