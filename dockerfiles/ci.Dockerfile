FROM circleci/buildpack-deps:18.04

ARG RUBY_VERSION

ENV RBENV_ROOT "/opt/rbenv"

RUN sudo mkdir /opt/rbenv && sudo chown -R circleci:circleci /opt/rbenv

RUN sudo apt-get update && sudo apt-get -y install build-essential postgresql-client
RUN git clone https://github.com/rbenv/rbenv.git $RBENV_ROOT
RUN git clone https://github.com/rbenv/ruby-build.git $RBENV_ROOT/plugins/ruby-build

ENV PATH "$PATH:/opt/rbenv/bin:/opt/rbenv/shims"

RUN rbenv install $RUBY_VERSION
RUN rbenv global $RUBY_VERSION
RUN gem install activesupport
