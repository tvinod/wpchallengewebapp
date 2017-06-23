FROM ruby:2.3.3
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /wpchallengewebapp
WORKDIR /wpchallengewebapp
ADD Gemfile /wpchallengewebapp/Gemfile
ADD Gemfile.lock /wpchallengewebapp/Gemfile.lock
RUN bundle install
ADD . /wpchallengewebapp
