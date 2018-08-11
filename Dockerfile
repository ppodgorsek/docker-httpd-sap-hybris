FROM fedora:28

MAINTAINER Paul Podgorsek <ppodgorsek@users.noreply.github.com>
LABEL description Httpd load-balancer with SSL termination in Docker

EXPOSE 80
EXPOSE 443

ENV BACKEND_HOSTS localhost
ENV BACKEND_PORT 8009
ENV BACKEND_PROTOCOL ajp

ENV SERVER_NAME localhost

ENV SSL_KEY_FILE localhost.key
ENV SSL_CRT_FILE localhost.crt

ENV HTTPD_VERSION 2.4.*
ENV MOD_SSL_VERSION 1:2.4.*

RUN dnf upgrade -y \
	&& dnf install -y \
		httpd-${HTTPD_VERSION} \
		mod_ssl-${MOD_SSL_VERSION} \
		iputils \
	&& dnf clean all

RUN mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/001-ssl.conf \
	&& rm -f /etc/httpd/conf.d/README \
		/etc/httpd/conf.d/autoindex.conf \
		/etc/httpd/conf.d/welcome.conf

COPY ssl/* /opt/ssl/
COPY conf/* /httpd-conf-fragments/

COPY scripts/define-configuration-and-start.sh /usr/local/bin/

CMD ["define-configuration-and-start.sh"]
