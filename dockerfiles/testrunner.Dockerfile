FROM circleci/ruby:2.6.1-stretch-browsers

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

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN RAILS_ENV=production bundle install --deployment --frozen --clean --without development --path vendor/bundle

COPY . /usr/src/app
COPY ./devproxyCA /usr/src/app/devproxyCA
COPY ./devproxyCA/cacert.pem /etc/ssl/certs/cacert.pem

ARG RAILS_ENV=production
ENV RAILS_ENV $RAILS_ENV

ARG TEST_FILES
ENV TEST_FILES $TEST_FILES

EXPOSE 3000
CMD ["sh", "-c", "bundle exec rspec --format documentation --format RSpec::Instafail --format RspecJunitFormatter --out /tmp/test-results/rspec.xml $TEST_FILES"]
