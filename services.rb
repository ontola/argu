require 'active_support'
require 'active_support/core_ext/hash'
require 'active_support/hash_with_indifferent_access'

SERVICES = {
  frontend: {
    manage_db: false,
    image: 'registry.gitlab.com/ontola/libro',
    command: 'java -jar cache.jar',
    health: 'curl -H "Host: argu.localtest" -f http://localhost:3080/link-lib/cache/status',
    port: 3080,
    restart: 'unless-stopped',
  },
  argu: {
    path: :apex,
    image: 'registry.gitlab.com/ontola/apex',
    health: 'curl -H "Host: argu.localtest" -f http://localhost:2999/argu/d/health',
    worker: {
      command: 'bundle exec sidekiq'
    }
  },
  email: {
    path: :email_service,
    subscriber: {
      command: 'bundle exec rake broadcast:subscribe',
      depends_on: 'rabbitmq'
    },
    worker: {
      command: 'bundle exec sidekiq -e staging'
    }
  },
  token: {
    path: :token_service,
    worker: {
      command: ' bundle exec sidekiq -e staging'
    }
  }
}.with_indifferent_access
