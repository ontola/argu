require 'active_support'
require 'active_support/core_ext/hash'
require 'active_support/hash_with_indifferent_access'

SERVICES = {
  frontend: {
    infra_name: 'frontend',
    manage_db: false,
    image: 'registry.gitlab.com/ontola/libro',
    command: 'node --use-openssl-ca ./dist/private/server.js',
    port: 8080,
    restart: 'unless-stopped',
  },
  argu: {
    infra_name: 'apex',
    path: :argu,
    image: 'registry.gitlab.com/ontola/apex',
    health: 'curl -H "Host: argu.localtest" -f http://localhost:2999/argu/d/health',
    worker: {
      command: 'bundle exec sidekiq'
    }
  },
  email: {
    infra_name: 'email',
    path: :email_service,
    image: 'registry.gitlab.com/ontola/email_service',
    subscriber: {
      command: 'bundle exec rake broadcast:subscribe',
      depends_on: 'rabbitmq'
    },
    worker: {
      command: 'bundle exec sidekiq -e staging'
    }
  },
  token: {
    infra_name: 'token',
    path: :token_service,
    image: 'registry.gitlab.com/ontola/token_service',
    worker: {
      command: ' bundle exec sidekiq -e staging'
    }
  },
  apex_rs: {
    infra_name: 'cache',
    image: 'registry.gitlab.com/ontola/apex-rs',
    command: '/usr/local/bin/server',
    env: {
      RUST_LOG: 'apex=debug,actix_web=debug,diesel=debug',
    },
    port: 3030,
    health: 'curl -H "Host: argu.localtest" -f http://localhost:3030/link-lib/d/health',
    setup: {
      command: '/usr/local/bin/migrate --version setup',
    },
    worker: {
      command: '/usr/local/bin/invalidator_redis',
    }
  }
}.with_indifferent_access
