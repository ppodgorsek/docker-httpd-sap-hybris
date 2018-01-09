# Httpd load-balancer with SSL termination in Docker

## What is it?

This project consists of a Docker image containing a load-balancer taking care of SSL termination, based on httpd.

## Versioning

The versioning of this image follows the one of Apache httpd:
* Major and minor versions match the ones of httpd
* Patch version is specific to this project (allows to update the versions of the other dependencies)

## Running the container

This container can be run using the following command:

    docker run -p 80:80\
        -p 443:443\
        ppodgorsek/httpd-ssl-balancer:<version>

### Backend servers

By default, all requests received on ports 80 and 443 will be forwarded to the AJP port (8009) on `localhost` (the Docker host).

You can change this behaviour by setting the following environment variables when running the image:
  * BACKEND_HOSTS=localhost
  * BACKEND_PORT=8009
  * BACKEND_PROTOCOL=ajp

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

