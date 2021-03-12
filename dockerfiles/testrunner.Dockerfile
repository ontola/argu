FROM registry.gitlab.com/ontola/core:base

COPY . /usr/src/app
COPY ./devproxyCA /usr/src/app/devproxyCA
COPY ./devproxyCA/cacert.pem /etc/ssl/certs/cacert.pem

ARG RAILS_ENV=production
ENV RAILS_ENV $RAILS_ENV

ARG TEST_FILES
ENV TEST_FILES $TEST_FILES

EXPOSE 3000
CMD ["sh", "-c", "bundle exec rspec --format documentation --format RSpec::Instafail --format RspecJunitFormatter --out /tmp/test-results/rspec.xml $TEST_FILES"]
