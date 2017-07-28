FROM ruby:2.4.1

# Install Rails library dependencies
RUN apt-get update && apt-get install -y \
  nodejs \
  postgresql-client \
  --no-install-recommends && rm -rf /var/lib/apt/lists/*

EXPOSE 80

# install rails
ENV APP_HOME=/usr/src/app \
    BUNDLER_VERSION=1.15.2 \
    RAILS_ENV=production \
    RAILS_VERSION=5.1.2

RUN gem install bundler:$BUNDLER_VERSION rails:$RAILS_VERSION && \
    gem cleanup all

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# create app dir
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

# copy gemfile and install gem dependencies
COPY Gemfile* $APP_HOME/
RUN bundle install --jobs=8 --without development:test

# copy the app into the image
COPY . $APP_HOME

# run rails
CMD bash -c 'bundle exec puma -C config/puma.rb'
