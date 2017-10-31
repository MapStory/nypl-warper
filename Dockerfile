FROM ubuntu:16.04

#RUN apt-get update -qq && apt-get install -y build-essential postgis libpq-dev nodejs imagemagick libmagickwand-dev cgi-mapserver gdal-bin libgdal-dev ruby-mapscript

# postgresql://localhost/blog_development?pool=5

RUN apt-get update -qq && apt-get install -y ruby libruby ruby-dev nodejs git postgis postgresql-server-dev-all imagemagick libmagickwand-dev cgi-mapserver gdal-bin libgdal-dev ruby-mapscript
RUN gem install bundle
RUN mkdir /myapp
WORKDIR /myapp
ADD Gemfile /myapp/Gemfile
ADD Gemfile.lock /myapp/Gemfile.lock
RUN bundle install
ADD . /myapp
ENV RAILS_ENV development
