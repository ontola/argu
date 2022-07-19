# Argu

**Open source e-democracy and community platform.**

See [argu.co](https://argu.co/info)

## Features

- **Ideation, discussions, voting**: all the tools you need to make decisions in a group.
- **Designed for engagement**: Responsive, accessible, easy to use. Creating an account takes as little clicks as possible.
- **Groups and rights management**: invite people with e-mails or unique URLs, have great control over what they are allowed to do
- **Powerful REST Linked Data API**: all data is re-usable, exportable and queryable

## Free managed hosting
You can use Argu for free! We host the software for you. [Click here to get started.](https://argu.co/argu/u/session/new?redirect_url=https%3A%2F%2Fargu.co%2Fargu%2Fo%2Fnew)

## Host yourself

See [infrastructure](https://gitlab.com/ontola/infrastructure) for the terraform config that can be used for deploying the stack to a production environment.

We provide services to help you setup Argu on your own machines and migrate data from our hosted environment. [Contact us](https://argu.co/info/contact) for more information.

## Setup locally

- Clone the repo, including the submodules 
  - `git clone --recurse-submodules -j8 git@gitlab.com:ontola/argu.git && cd argu`
- If you already cloned without the submodules, you can initialize them by running 
  - `git submodule update --init --recursive`
- Make sure you have docker and docker-compose installed.
- Run the following command once to create a local certificate, update your hosts file and prepare the .env files
  - `./bin/install.sh`
- Start the services. All containers will run in production-ready docker images by default. 
  If you want to do development or if you want more performance, read more about Environments below.
  - `./bin/dev.sh`
- Initialize the databases.
  - `./bin/initialize_db.sh`
- Go to https://argu.localdev/argu
- Log in with `staff@example.com` and `password` to use the app as staff, or register a new account.
- Mails sent by the application will be catched by Mailcatcher. You can see them at http://localhost:1080.

## Environments

There are two different environments to run the stack: dev and test.

You can boot these environments by running either `./bin.dev.sh` or `./bin/test.sh`.

Read more about the test suite below.

### .env
The environment variables used by all services are present in the `.env` files. 
Both environments have their own file: `.env.dev` and `.env.test`. 
When switching your environment, a symlink is created from `.env` to the appropriate file.

### Seeds
The seeds of the environments are different. 
The dev seed contains less data. Its default website can be found at https://argu.localdev/argu. 
The test seed contains more generated content, used by the end-to-end testing. Its default website can be found at https://argu.localtest/argu.

### Databases
Both environments use different databases. The test database is reset after each test when running the end-to-end tests.

To setup and (re)seed the database for the currently booted environment, run `/bin/initialize_db`.

## Architecture
The Argu software consists of the following components:

- Apex: A Ruby on Rails server that contains most of the business logic.
- Libro-client: A react / typescript front-end GUI that runs in the browser.
- Libro-server: A Kotlin KTOR server application that hosts the front-end, deals with authentication and servers as a cache
- Token service: A Ruby on Rails server that contains logic for invites.
- Email service: A Ruby on Rails server that contains logic for sending emails.

## Development containers and running natively

By default, all services will run in a production-ready docker container pulled from the registry.

There are two other ways to run a service: using development containers and running natively. 
To switch, you need to alter the COMPOSE_PROFILES in your `.env` file and run `./bin/restart.sh`. 
Read further for more information. 

In the production-ready image, the libro client bundle is served by the libro server.
In development or when running natively, a dev server runs at port 3001 to serve and hotreload the client code.

***Please note that running the stack in docker requires a lot of memory, especially when using the dev containers.
The dev docker containers also need more disk space for installing all dependencies.***

***When running on a mac M1 chip, running the services natively is highly recommended for performance reasons.***

### Development container

You can run services in a development image. The code from the submodules in the `services` directory will be mounted as a volume. 
This allows you to edit the code right away without any additional dev setup.

To run a service in a development image, append -dev to the COMPOSE_PROFILES in the `.env` file, 
e.g. `COMPOSE_PROFILES=apex-dev,libro,email,token` and run `./bin/restart.sh`

### Running natively

Running the containers in Docker on a Mac or Windows can be quite slow though, especially when running on a Mac M1 chip. 
You can also decide to run some of the services natively on your machine.
This requires you to prepare your machine for local development first.

- Remove the service from `COMPOSE_PROFILES` in the `.env`, e.g. `COMPOSE_PROFILES=libro,email,token` and run `./bin/restart.sh`
- The service running locally will try to connect to connect to services running in docker. The ports are all exposed, so this should not be a problem. However, it uses specific hostnames instead of `localhost`. 
  Run this command to update your hosts file: 
  - ``echo 127.0.0.1 elastic postgres redis mailcatcher token.svc.cluster.localdev email.svc.cluster.localdev apex.svc.cluster.localdev libro.svc.cluster.localdev >> /etc/hosts`` 
- Install the required dependencies for running the specific services natively. See the submodules for more info.
- Boot the server natively.

### Workers
Apex and the Token service both have a Sidekiq background worker running in a separate container. 
These are always running in the production-ready built image. 

If you want to run these processes natively, you should stop these containers manually.

## Testing

Each package and service has its own test suite. On top of that, this repo also provides a test suite for end-to-end browser testing.

- Run `./bin/test.sh` to spin up the test environment.
- Run `./bin/initialize_db.sh` if it’s the first time running tests or the seed data has changed.
- Run the tests using one of these methods:
    - `docker-compose exec testrunner bundle exec rspec` to run in docker
    - `bundle exec rspec` in the `test` directory to run locally. This requires ruby and installing the gems first.
    - Use your IDE

This test suite is still a bit flaky though.

## Commands

### Seeding
`./bin/initialize_db.sh` 

The DB is seeded with user `staff@example.com` and password `password`.

### Restart all services
`./bin/restart.sh` 

### Install dependencies and run migrations
`./bin/update.sh`

### Pull from remote
`./bin/pull.sh`

This will also call `./bin/update.sh`

## Elasticsearch

Elasticsearch is used for searching. 
If the search is not working, you might need to reindex the tree. 
You can do this by running the following command in a rails console in Apex:
```
Edge.reindex_with_tenant(async: false)
```

If you run into problems with search, you can disable the search indexing by setting `DISABLE_SEARCHKICK=true`.

## CI

The CI runs at [Gitlab](https://gitlab.com/ontola/argu/-/pipelines).

Set the max [timeout](https://www.man7.org/linux/man-pages/man1/timeout.1.html)
of the test run by setting the TEST_TIMEOUT env. This can be useful to gather
artifacts quickly or when otherwise unavailable due to CI timeout.

## Contributing

Want to contribute to this project?

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

All software used for running Argu is either [MIT](https://tldrlegal.com/license/mit-license) or [AGPL](https://tldrlegal.com/license/gnu-affero-general-public-license-v3-(agpl-3.0)) licensed, see the respective projects for the license in question.
