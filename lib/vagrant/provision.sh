#!/usr/bin/env bash

# Created for Ubuntu 16.04 LTS
# with bento/ubuntu-16.04 vagrant box
# 
# Ruby 2.3 


# make sure we have up-to-date packages
apt-get update

## vagrant grub-pc fix from: https://gist.github.com/jrnickell/6289943
# parameters
#echo "grub-pc grub-pc/kopt_extracted boolean true" | debconf-set-selections
#echo "grub-pc grub2/linux_cmdline string" | debconf-set-selections
#echo "grub-pc grub-pc/install_devices multiselect /dev/sda" | debconf-set-selections
#echo "grub-pc grub-pc/install_devices_failed_upgrade boolean true" | debconf-set-selections
#echo "grub-pc grub-pc/install_devices_disks_changed multiselect /dev/sda" | debconf-set-selections
# vagrant grub fix
#dpkg-reconfigure -f noninteractive grub-pc

# upgrade all packages
#apt-get upgrade -y

# install packages as explained in INSTALL.md
# apt-get install -y ruby1.9.1 libruby1.9.1 ruby1.9.1-dev ri1.9.1 \
#     postgresql-9.3-postgis-2.1 postgresql-server-dev-all postgresql-contrib \
#     build-essential git-core \
#     libxml2-dev libxslt-dev imagemagick libmapserver1 gdal-bin libgdal-dev ruby-mapscript nodejs libmagickwand-dev redis-server


apt-get install -y ruby libruby ruby-dev nodejs git \
		build-essential postgresql-9.5-postgis-2.2 postgis postgresql-server-dev-all postgresql-contrib \
		imagemagick libmagickwand-dev cgi-mapserver gdal-bin libgdal-dev ruby-mapscript redis-server

#ruby gdal needs the build Werror=format-security removed currently
#sed -i 's/-Werror=format-security//g' /usr/lib/ruby/1.9.1/x86_64-linux/rbconfig.rb
 
#gem1.9.1 install bundle

gem install bundle


# Warning, this will add multiple times if re-running provision script.
echo "export RAILS_ENV=development" >> /home/vagrant/.bashrc


## install the bundle necessary for mapwarper
pushd /srv/mapwarper

# do bundle install as a convenience
sudo -u vagrant -H bundle install 
# create user and database for openstreetmap-website
db_user_exists=`sudo -u postgres psql postgres -tAc "select 1 from pg_roles where rolname='vagrant'"`
if [ "$db_user_exists" != "1" ]; then
		sudo -u postgres createuser -s vagrant
		sudo -u vagrant -H createdb -E UTF-8 -O vagrant mapwarper_development
fi

# build and set up postgres extensions
# TODO: Is this still needed at all? Or is this taken care of with the postgis package?
sudo -u vagrant psql mapwarper_development -c "create extension postgis;"


# set up sample configs
if [ ! -f config/database.yml ]; then
		sudo -u vagrant cp config/database.example.yml config/database.yml
fi
if [ ! -f config/application.yml ]; then
		sudo -u vagrant cp config/application.example.yml config/application.yml
fi
if [ ! -f config/secrets.yml ]; then
		sudo -u vagrant cp config/secrets.yml.example config/secrets.yml
fi



echo "now migrating database. This may take a few minutes"
# migrate the database to the latest version
sudo -u vagrant -H RAILS_ENV=development bundle exec rake db:migrate
popd
