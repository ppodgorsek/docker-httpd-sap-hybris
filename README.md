# Httpd load-balancer with SSL termination in Docker

## What is it?

This project consists of a Docker image containing a load-balancer taking care of SSL termination, based on httpd.

It allows to use a dedicated folder for any custom configuration for httpd.

## Versioning

The versioning of this image follows the one of Apache httpd:

* Major version matches the one of httpd
* Minor and patch versions are specific to this project (allows to update the versions of the other dependencies)

The current versions used are:

* httpd 2.4
* mod_ssl 2.4

## Running the container

This container can be run using the following command:

    docker run \
        -p 80:80 \
        -p 443:443 \
        ppodgorsek/httpd-ssl-balancer:<version>

### Server name

The `ServerName` directive can be defined by setting the `SERVER_NAME` environment variable, as per the following example:

    docker run \
        -e SERVER_NAME=myserver.com \
        ppodgorsek/httpd-ssl-balancer:<version>

It will be defined in a specific configuration file which will be created for that purpose when the container starts: `/etc/httpd/conf.d/000-server-details.conf`

By default, it is set to `localhost`.

### Defining custom configuration

If you would like to use custom configuration files, simply place them in a folder and mount it as a volume:

    docker run \
        -v <local path to folder containing configuration files>:/etc/httpd/conf.d:Z \
        ppodgorsek/httpd-ssl-balancer:<version>

All `*.conf` files placed in that folder will be loaded in addition to a minimal httpd configuration.
Remember, those files will be imported in alphabetical order.

### Backend servers

By default, all requests received on ports 80 and 443 will be forwarded to the AJP port (8009) on `localhost` (the Docker host).

You can change this behaviour by setting the following environment variables when running the image:
  * BACKEND_HOSTS (default: `localhost`, the Docker host)
  * BACKEND_PORT (default: `8009`)
  * BACKEND_PROTOCOL (default: `ajp`)

A list of backend hosts can be provided as a list separate by commas, for example:

    docker run -p 80:80\
        -p 443:443\
        -e BACKEND_HOSTS=server1.mydomain.com,server2.mydomain.com\
        ppodgorsek/httpd-ssl-balancer:<version>

The accepted backend protocols are:
  * ajp
  * http

Be aware that all backend servers must use the same port and protocol.

### SSL

A default self-signed certificate has been generated for `localhost`. You can use your own certificate by mounting its location as a volume and by defining the corresponding environment variables:

    docker run -p 80:80\
        -p 443:443\
        -v <local path to the certificate's folder>:/opt/ssl:Z\
        -e SSL_KEY_FILE=mydomain.key\
        -e SSL_CRT_FILE=mydomain.crt\
        ppodgorsek/httpd-ssl-balancer:<version>

The certificate files is relative to the folder which has been mounted.

## Please contribute!

Have you found an issue? Do you have an idea for an improvement? Feel free to contribute by submitting it [on the GitHub project](https://github.com/ppodgorsek/docker-httpd-ssl-balancer/issues).
