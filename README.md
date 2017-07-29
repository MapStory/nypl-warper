# Map Warper for MapStory

This project is forked from the NYPL Map Warper and altered to
provide integration with MapStory.

If you're interested in the project it's best to use the NYPL version
which is available at https://github.com/nypl-spacetime/nypl-warper



## Features

* Find and search maps by geography
* Adding control points to maps side by side
* Crop maps
* User commenting on maps
* Align maps from similar
* Login via Github / Twitter / etc
* OR signup with email and password
* Export as GeoTiff, PNG, WMS, Tile, KML etc
* Preview in Google Earth and Google Maps
* Map Favourites
* Social media sharing
* Bibliographic metatadata creation and export support
* Multiple georectfication options
* Control point from files import
* API
* Admin tools include
  * User statistics
  * Activity monitoring
  * User administration, disabling
  * Roles management (editor, developer, admin etc)
  * Batch Imports
  * User Statistics
  * Revisions and Rollbacks
 

## Ruby & Rails

* Rails 4.2
* Ruby 2.3+

## Database

* Postgresql 9.1 (or 9.1, 8.4)
* Postgis 2 (may work with 1.5)

## Installation Dependencies

Check out the Vagrant section lower down in the readme if you want to get started quickly.

on Ubuntu 16.04 LTS

```apt-get install -y ruby ruby-dev postgresql-9.3-postgis-2.1 postgresql-server-dev-all postgresql-contrib build-essential git-core libxml2-dev libxslt-dev imagemagick libmapserver1 gdal-bin libgdal-dev ruby-mapscript nodejs```

Due to a bug with the gdal gem, you _may_ need to disable a few flags from your ruby rbconfig.rb see https://github.com/zhm/gdal-ruby/issues/4 for more information

Then install the gem files using bundler

```bundle install```


## Configuration

Create and configure the following files

* `config/secrets.yml`
* `config/database.yml`
* `config/application.yml`

In addition have a look in `config/initializers/application_config.rb `for some other paths and variables, and `config/initializers/devise.rb ` for devise and omniauth and also `config/environments/development.rb` if you rather not use the `/warper` relative path.

## Database creation

Create a postgis database

    sudo -u postgres createdb mapwarper_development
    psql mapwarper_development -c "create extension postgis;"
    RAILS_ENV=development bundle exec rake db:migrate

## Database initialization

Creating a new user

    user = User.new
    user.login = "super"
    user.email = "super@superxyz123.com"
    user.password = "your_password"
    user.password_confirmation = "your_password"
    user.confirmed_at = Time.now
    user.save

    role = Role.find_by_name('super user')

    permission  = Permission.new
    permission.role = role
    permission.user = user
    permission.save

    role = Role.find_by_name('administrator')
    permission = Permission.new
    permission.role = role
    permission.user = user
    permission.save

Also, you can run `rake db:seed` to add in a default admin user


## Development 

Via [Vagrant](https://www.vagrantup.com/), there is a [`Vagrantfile`](/Vagrantfile) you can use which uses the [`/lib/vagrant/provision.sh`](/lib/vagrant/provision.sh) provision script. **Note:** the default `Vagrantfile` is configured to take 8GB RAM. To use this file type:

    vagrant up

to get and install the virtual machine - this will also install the libraries and depencies and ruby gems for mapwarper into the virtual machine. See [`/lib/vagrant/provision.sh`](/lib/vagrant/provision.sh) for more details about this process.

After that runs, type `vagrant ssh` to login and then you can:

    cd /srv/mapwarper
    rails c

Create a user in the console, as [shown above](#database-initialization) and then `exit`. Then start the server in a relative url root use `thin`:

    rails s -b 0.0.0.0

and then browse to `http://localhost:3000/`

In non-Vagrant circumstances you may want to run it just using `rails s`.


## Deployment instructions

The system can use capistrano for deployment.

### Making Code Changes and Deployment

There are two main changes to the system. Changes to checked in code, and changes to configuration files. Some configuration files (`/config/*`) are not stored in the repository. To change these you need to ssh into the server and change the file. Some `.example` files are provided for reference.

#### Changes to checked in code.

Develop, patch the code locally and get it running. Probably the easiest way to start developing is via Vagrant, see above for more details. Once you have Vagrant running, these are some useful commands to make sure updates are reflected:

##### If assets had been changed (images, JS, CSS etc.) or if you just want to be safe:

 `RAILS_ENV=production rake assets:clobber`

 `RAILS_ENV=production rake assets:precompile`

##### If necessary to run rails console commands:

 `RAILS_ENV=production rails console`

##### To restart the server:

`touch tmp/restart.txt`

##### To restart the Apache server (not needed in almost all cases):

`sudo service apache2 restart`

##### Changes to config file:

1. ssh into the server
2. Find the desired config file
3. Edit the file
4. Restart the warper: `touch tmp/restart.txt`

## API

See [`README_API.md`](/README_API.md) for API details


