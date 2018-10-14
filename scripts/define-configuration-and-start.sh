#!/bin/bash

. /opt/httpd/bin/network-utils.lib

DOCKER_MAC_HOST="docker.for.mac.localhost"
DOCKER_WINDOWS_HOST="docker.for.win.localhost"

CONF_FRAGMENTS_FOLDER=/httpd-conf-fragments
HTTPD_DEFAULT_CONF_FOLDER=/etc/httpd/default.conf.d
HTTPD_CONF_FOLDER=/etc/httpd/conf.d
HTTPD_CUSTOM_CONF_FOLDER=/etc/httpd/custom.conf.d

echo "Defining the server name as: ${SERVER_NAME}"
echo "ServerName ${SERVER_NAME}" > ${HTTPD_DEFAULT_CONF_FOLDER}/000-server-details.conf

echo "Request timeout: ${SERVER_REQUEST_TIMEOUT}"
echo "Timeout ${SERVER_REQUEST_TIMEOUT}" >> ${HTTPD_DEFAULT_CONF_FOLDER}/001-request-timeout.conf

echo "Server signature: ${SERVER_SIGNATURE}"
echo "ServerSignature ${SERVER_SIGNATURE}" >> ${HTTPD_DEFAULT_CONF_FOLDER}/002-server-signature.conf

if [ "${SERVER_ADMIN_EMAIL}" != "" ]
then
	echo "Server admin email: ${SERVER_ADMIN_EMAIL}"
	echo "ServerAdmin ${SERVER_ADMIN_EMAIL}" >> ${HTTPD_DEFAULT_CONF_FOLDER}/002-server-signature.conf
fi

echo "Backend hosts: ${BACKEND_HOSTS}"
echo "Backend port: ${BACKEND_PORT}"
echo "Backend protocol: ${BACKEND_PROTOCOL}"

cp -R ${HTTPD_CONF_FOLDER}/* ${HTTPD_CUSTOM_CONF_FOLDER}/

sed -i -e "s/SSLCertificateFile .*/SSLCertificateFile \/opt\/ssl\/${SSL_CERTIFICATE_FILE}/g" ${CONF_FRAGMENTS_FOLDER}/002-default-ssl.conf
sed -i -e "s/SSLCertificateKeyFile .*/SSLCertificateKeyFile \/opt\/ssl\/${SSL_KEY_FILE}/g" ${CONF_FRAGMENTS_FOLDER}/002-default-ssl.conf

if [ "${SSL_CA_CERTIFICATE_FILE}" != "" ]
then
	sed -i -e "s/#SSLCACertificateFile .*/SSLCACertificateFile \/opt\/ssl\/${SSL_CA_CERTIFICATE_FILE}/g" ${CONF_FRAGMENTS_FOLDER}/002-default-ssl.conf
fi

determineLocalhost
generateDefaultVirtualHosts

case ${SERVER_FORCE_HTTPS} in
	"true" )
		rm -f $HTTPD_DEFAULT_CONF_FOLDER/001-http-backend.conf
		break;;
	"false" )
		rm -f $HTTPD_DEFAULT_CONF_FOLDER/001-http-redirection.conf
		break;;
	* )
		echo "The SERVER_FORCE_HTTPS environment variable can only be true or false"
		exit;;
esac

# Replace the default SSL configuration wherever required
defaultSslConfiguration=`cat ${CONF_FRAGMENTS_FOLDER}/002-default-ssl.conf`
for i in `ls ${HTTPD_DEFAULT_CONF_FOLDER} ${HTTPD_CUSTOM_CONF_FOLDER}`
do
	sed -i -e "s/\$[{]DEFAULT_SSL_CONFIGURATION[}]/$defaultSslConfiguration/g" $i
	sed -i -e "s/\/\/localhost/\/\/${RESOLVED_LOCALHOST}/g" $i
done

# Continue with the usual startup
httpd -DFOREGROUND
