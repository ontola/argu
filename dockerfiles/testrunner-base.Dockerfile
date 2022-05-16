FROM mcr.microsoft.com/playwright:v1.21.0-focal

RUN apt-get -qy update && apt-get -qfy install docker git tzdata openssh-client \
        build-essential libxml2-dev libffi-dev libxslt-dev liblzma-dev libssl-dev zlib1g-dev \
        && rm -rf /var/cache/apk/*


RUN git clone https://github.com/rbenv/rbenv.git /root/.rbenv; \
    git clone https://github.com/rbenv/ruby-build.git /root/.rbenv/plugins/ruby-build; \
    /root/.rbenv/plugins/ruby-build/install.sh; \
    /root/.rbenv/bin/rbenv install 3.0.2
ENV PATH /root/.rbenv/versions/3.0.2/bin:$PATH

RUN npx playwright install chromium

USER root:root

RUN gem install bundle bundler
# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1
RUN bundle config build.nokogiri --use-system-libraries

RUN mkdir -p /tmp/test-results
WORKDIR /usr/src/app
RUN chown -R $(whoami):$(whoami) /usr/src/app
RUN chown -R $(whoami):$(whoami) /tmp/test-results

RUN bundle config clean 'true'
RUN bundle config deployment 'true'
RUN bundle config frozen 'true'
RUN bundle config path 'vendor/bundle'
RUN bundle config without 'development'

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN RAILS_ENV=production bundle install
