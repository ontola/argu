# Argu Devproxy

This serves as the installer, testing suite and development proxy server for all Argu services.

## Installation

1. [Get the install script](https://bitbucket.org/arguweb/devproxy/downloads/install.sh) or clone/download this repo.
1. Run `./install.sh`

## Setup ENV

1. Run `./setup.sh`.
1. Set the Mapquest and nomatim keys (see `env.template` for where you can find them)
1. Run the following commands in your local Argu backend Rails Console and set the .env variables:

```
ARGU_APP_ID = Doorkeeper::Application.argu.uid
ARGU_APP_SECRET = Doorkeeper::Application.argu.secret
RAILS_OAUTH_TOKEN = Doorkeeper::Application.argu_front_end.access_tokens.find_by(scopes: :service).token
SERVICE_TOKEN = Doorkeeper::Application.argu.access_tokens.find_by(scopes: :service).token
```

## Usage

1. Install Docker and the [Google Cloud SDK](https://cloud.google.com/sdk/)
1. Set up the authentication for the Argu Gcloud registries.
1. Run `./dev.sh` to start all Argu services.
1. Visit https://app.argu.localdev/

## Using local services

1. Copy the Local Ports config template: `cp template.local_ports.yml local_ports.yml`
1. Uncomment or add the locally running service in `local_ports.yml`.
1. Note: stop the respective docker service manually, if it's still running. `docker stop ${service_name}`

## Testing

1. Run `./test.sh`
2. Run `bundle exec rake test:setup` if it’s the first time running tests
3. Run tests with `bundle exec rspec` or in your IDE

## Restarting services

Run `./restart.sh %{service_name}`, e.g. `./restart.sh argu`

## Updating services

Run `./update.sh` to pull the latest images and run migrations.

## When your CSRF token is wrong

Run `./sync_tokens.sh` and follow the instructions.
