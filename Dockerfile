FROM fedora:28

MAINTAINER Paul Podgorsek <ppodgorsek@users.noreply.github.com>
LABEL description Httpd load-balancer with SSL termination in Docker

EXPOSE 80
EXPOSE 443

ENV BACKEND_HOSTS localhost
ENV BACKEND_PORT 8009
ENV BACKEND_PROTOCOL ajp

ENV SERVER_ADMIN_EMAIL ""
ENV SERVER_FORCE_HTTPS true
ENV SERVER_NAME localhost
ENV SERVER_REQUEST_TIMEOUT 120
ENV SERVER_SIGNATURE Off

ENV SSL_KEY_FILE localhost.key
ENV SSL_CERTIFICATE_FILE localhost.crt
ENV SSL_CA_CERTIFICATE_FILE ""

ENV HTTPD_VERSION 2.4.*
ENV MOD_SSL_VERSION 1:2.4.*

RUN dnf upgrade -y \
	&& dnf install -y \
		httpd-${HTTPD_VERSION} \
		mod_ssl-${MOD_SSL_VERSION} \
		iproute \
		iputils \
	&& dnf clean all

COPY ssl/* /opt/ssl/
COPY conf/default/* /etc/httpd/default.conf.d/
COPY conf/fragments/* /httpd-conf-fragments/

RUN sed -i -e 's/IncludeOptional conf\.d\/\*\.conf/IncludeOptional default.conf.d\/*.conf\nIncludeOptional custom.conf.d\/*.conf/g' /etc/httpd/conf/httpd.conf \
	&& rm -f /etc/httpd/conf.d/* \
	&& mkdir /etc/httpd/custom.conf.d

COPY scripts/* /opt/httpd/bin/

CMD ["/opt/httpd/bin/define-configuration-and-start.sh"]
