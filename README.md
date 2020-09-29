# Argu Devproxy

This serves as the installer, testing suite and development proxy server for all Argu services.

## Installation

1. [Get the install script](https://bitbucket.org/arguweb/devproxy/downloads/install.sh) or clone/download this repo.
1. Run `./install.sh` NOTE: This script is currently not up to date.

## Usage

1. Make sure node, docker, docker-compose, ruby and the [Google Cloud SDK](https://cloud.google.com/sdk/) are installed and available in your shell path.
1. Sign in to our gitlab registry, make sure you have the correct rights. `docker login registry.gitlab.com`. When asked for a password, enter a [gitlab personal access token](https://gitlab.com/profile/personal_access_tokens) with access to the registry (tick `api`).
1. Set up the authentication for the Argu GCloud registries. `
1. Set up your ENV variables (see below)
1. Set up the database `rake db:setup` from the `argu` image. Access the image using `docker-compose exec argu sh`.
1. Run `./dev.sh` to start all Argu services.
1. Add a lot of things to `/etc/hosts` (all the docker services to localhost)
1. Visit https://argu.localdev/
1. If you're encountering HTTPS / SSL issues, manually approve the certificate. In macOS, you can do this by adding `./ssl/nginx.cert` to Keychain.

## Setup ENV

1. Set the Mapbox key (see `env.template` for where you can find it)
1. Run the following commands in your local Argu backend Rails Console (e.g. `docker-compose exec argu bundle exec rails c`) and set the .env variables:

```
ARGU_APP_ID = Doorkeeper::Application.argu.uid
ARGU_APP_SECRET = Doorkeeper::Application.argu.secret
RAILS_OAUTH_TOKEN = Doorkeeper::Application.argu_front_end.access_tokens.find_by(scopes: :service).token
SERVICE_TOKEN = Doorkeeper::Application.argu.access_tokens.find_by(scopes: :service).token
```

## Using local services

By default, all the services are running using Docker-Compose.
During development, you're likely to run specific services locally, without docker.
Specify these with the `local_ports.yml` file.

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

## CI

Set the max [timeout](https://www.man7.org/linux/man-pages/man1/timeout.1.html)
of the test run by setting the TEST_TIMEOUT env. This can be useful to gather
artifacts quickly or when otherwise unavailable due to CI timeout.
