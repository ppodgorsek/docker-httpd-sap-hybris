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

COPY ssl/* /opt/ssl/
COPY conf/fallback/* /etc/httpd/fallback.conf.d/
COPY conf/fragments/* /httpd-conf-fragments/

RUN sed -i -e 's/IncludeOptional conf\.d\/\*\.conf/IncludeOptional default.conf.d\/*.conf\nIncludeOptional conf.d\/*.conf\nIncludeOptional fallback.conf.d\/*.conf/g' /etc/httpd/conf/httpd.conf \
	&& mkdir /etc/httpd/default.conf.d \
	&& mv /etc/httpd/conf.d/ssl.conf /etc/httpd/default.conf.d/001-ssl.conf \
	&& rm -f /etc/httpd/conf.d/*

COPY scripts/define-configuration-and-start.sh /usr/local/bin/

CMD ["define-configuration-and-start.sh"]
