# Gemirro | [![Build Status](https://travis-ci.org/PierreRambaud/gemirro.svg?branch=master)](https://travis-ci.org/PierreRambaud/gemirro) [![Gem Version](https://badge.fury.io/rb/gemirro.svg)](http://badge.fury.io/rb/gemirro)

Gemirro allows you to cache Ruby gems in your local network and [run your own gem server](http://guides.rubygems.org/run-your-own-gem-server/).

By default it does not require any authentication and you can also add your private gems in the `gems` directory.

## Requirements

* Ruby 1.9.2 or newer
* Enough space to store Gems

## Installation

```bash
$ gem install gemirro
```

## Usage

### Initialize the mirror directory

Once the gem is installed, use `gemirro init` to setup an empty mirror:

```bash
$ gemirro init /srv/http/mirror.com/
```

This command generates a set of directories and a configuration file called `config.rb`.
This configuration file specifies what gem source to mirror, its destination directory, server host and port, etc.

### Start the server

Run `gemirro server` to start the gem server. By default, the server process will listen on port 2000:

```bash
$ gemirro server --start
$ gemirro server --status
$ gemirro server --restart
$ gemirro server --stop

```

If there is a request for a gem that is not yet cached, Gemirro fetches gems from RubyGems and updates its index.

### Update mirrored gems

Edit `config.rb`:

Update and index:


Once configured and if you add gem in the `define_source`, you can pull them by running the following command:

```bash
$ gemirro update
```

Once all the Gems have been downloaded you'll need to generate an index of all the installed files. This can be done as following:

```bash
$ gemirro index
```

### Run a different Gemirro configuration


If you want to use a custom configuration file not located in the current directory, use the `-c` or `--config` option.

## Web servers configuration

### Apache

You must active the apache `proxy` module.

```bash
$ sudo a2enmod proxy
$ sudo a2enmod proxy_http
```

Create your VirtualHost and replace following `http://localhost:2000` with your custom server configuration located in your `config.rb` file and restart Apache.

```
<VirtualHost *:80>
  ServerName mirror.gemirro
  ProxyPreserveHost On
  ProxyRequests off
  ProxyPass / http://localhost:2000
  ProxyPassReverse / http://localhost:2000
</VirtualHost>
```

### Nginx

Replace `localhost:2000` with your custom server configuration located in your `config.rb` file and restart Nginx.

```
upstream gemirro {
  server localhost:2000;
}

server {
  server_name rbgems;

  location / {
    proxy_pass http://gemirro;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
```

## Known issues

### could not find a temporary directory

If you use ruby >= 2.0, some urls in the server throwing errors telling `could not find a temporary directory`.
You only need to do a `chmod o+t /tmp`

### Gem::RemoteFetcher::FetchError

If you see this error (`bad response Bad Gateway 502`), then Gemirro is still building its cache.