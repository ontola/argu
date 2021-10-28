# Ontola Core

Core serves as a testing suite and development proxy server for various Ontola projects, such as Argu.

## Usage (for setting up Argu)

1. Make sure `docker` is running and `ruby` (2.x) is available in path.
1. `docker login registry.gitlab.com`. Sign in to our gitlab registry, make sure you have the correct rights.
1. When asked for a password, enter a [gitlab personal access token](https://gitlab.com/-/profile/personal_access_tokens) with access to the registry (tick `api`).
1. `git clone` [apex](https://gitlab.com/ontola/apex) and [libro](https://gitlab.com/ontola/libro), if you need to run them locally.
1. `bundle install` install dependencies for running the `setup_environment.rb`
1. `./dev.sh` should fix the rest, but is prone to errors. Keep a close look at the output! If things fail, you might need to do it manually:
  1. Set up your ENV variables (see [Setup ENV](#setup-env) below)
  1. Copy `apex/config/secrets.docker.yml` to `apex/config/secrets.yml`
  1. Copy `apex/config/database.docker.yml` to `apex/config/database.yml`
  1. Add stuff to `/etc/hosts` (see [Hosts](#hosts))
1. Set up the database. If you're running `apex` locally, go there and run `bundle exec rake db:setup`, if you're running from docker, first enter the running docker image `docker-compose exec argu sh` and run the same command.
1. Run `./dev.sh` to start all Argu services.
1. Visit https://argu.localdev/

## Setup ENV

1. Copy `.env.template` to `.env.dev`
1. Symlink it to `.env` like this `ln -s .env.dev .env`
1. Symlink it to all projects that you're running locally (e.g. libro, apex), make sure to do this in the target directory: `cd ../apex` and then run `ln -s ../core/.env.dev .env`
1. Set the Mapbox key (see `env.template` for where you can find it)
1. Run the following commands in your local Argu backend Rails Console (e.g. `docker-compose exec argu bundle exec rails c`) and set the .env variables:

```
ARGU_APP_ID = Doorkeeper::Application.argu.uid
ARGU_APP_SECRET = Doorkeeper::Application.argu.secret
RAILS_OAUTH_TOKEN = Doorkeeper::Application.argu_front_end.access_tokens.find_by(scopes: :service).token
SERVICE_TOKEN = Doorkeeper::Application.argu.access_tokens.find_by(scopes: :service).token
```
## Hosts

Core needs a lot of `/etc/hosts`:

```
127.0.0.1 argu.localdev
127.0.0.1 app.argu.localdev
 ::1 argu.localdev
127.0.0.1 argu.localtest
127.0.0.1 app.argu.localtest
 ::1 argu.localtest
127.0.0.1 dexpods.localdev
127.0.0.1 elastic
127.0.0.1 elastic_search
127.0.0.1 postgres
127.0.0.1 redis
127.0.0.1 rabbitmq
127.0.0.1 mailcatcher
127.0.0.1 token.svc.cluster.local
127.0.0.1 email.svc.cluster.local
127.0.0.1 argu.svc.cluster.local
127.0.0.1 cache.svc.cluster.local
127.0.0.1 dextransfer.localdev
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

## Troubleshooting

### HTTPS / SSL issues

Manually approve the certificate. In macOS, you can do this by adding `./ssl/nginx.cert` to the Keychain Access app. Add the certificate by pressing `cmd+shift+i`.

### Postgres `wrong password`

- Make sure the `.env` password does not look like `{postgres_password}`
- Check the `.env` here and in `apex`
- Check if there are other postgres instances running `sudo lsof -nP -iTCP -sTCP:LISTEN | grep 5432`
