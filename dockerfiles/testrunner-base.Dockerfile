FROM circleci/ruby:2.7-buster-browsers

RUN sudo apt-get -qy update && sudo apt-get -qfy install docker git tzdata openssh-client build-essential libxml2-dev \
        libffi-dev libxslt-dev liblzma-dev \
        && rm -rf /var/cache/apk/*

USER root:root

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1
RUN bundle config build.nokogiri --use-system-libraries

RUN sudo mkdir -p /tmp/test-results
WORKDIR /usr/src/app
RUN sudo chown -R $(whoami):$(whoami) /usr/src/app
RUN sudo chown -R $(whoami):$(whoami) /tmp/test-results

RUN bundle config clean 'true'
RUN bundle config deployment 'true'
RUN bundle config frozen 'true'
RUN bundle config path 'vendor/bundle'
RUN bundle config without 'development'

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN RAILS_ENV=production bundle install
