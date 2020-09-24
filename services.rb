require 'active_support'
require 'active_support/core_ext/hash'
require 'active_support/hash_with_indifferent_access'

SERVICES = {
  apex_rs: {
    image: 'registry.gitlab.com/ontola/apex-rs',
    command: '/usr/local/bin/server',
    env: {
      RUST_LOG: 'apex=debug,actix_web=debug,diesel=debug',
    },
    port: 3030,
    health: 'curl -H "Host: argu.localtest" -f http://localhost:3030/link-lib/d/health',
    setup: {
      command: '/usr/local/bin/migrate --version setup',
    }
  },
  frontend: {
    manage_db: false,
    image: 'registry.gitlab.com/ontola/libro',
    command: 'node --use-openssl-ca ./dist/private/server.js',
    port: 8080
  },
  argu: {
    path: :argu,
    image: 'registry.gitlab.com/ontola/apex',
    health: "curl -H 'Host: argu.localtest' -f http://localhost:2999/argu/d/health"
  },
  email: {
    path: :email_service
  },
  token: {
    path: :token_service
  }
}.with_indifferent_access
