#!/bin/bash

echo "Hybris backend hosts: ${BACKEND_HOSTS}"
echo "Hybris backend port: ${BACKEND_PORT}"
echo "Hybris backend protocol: ${BACKEND_PROTOCOL}"

CONF_FRAGMENTS_FOLDER=/httpd-conf-fragments
HTTPD_CUSTOM_CONF_FOLDER=/etc/httpd/conf.d

sed -i -e "s/SSLCertificateFile .*/SSLCertificateFile \/opt\/ssl\/${SSL_CRT_FILE}/g" ${HTTPD_CUSTOM_CONF_FOLDER}/001-ssl.conf
sed -i -e "s/SSLCertificateKeyFile .*/SSLCertificateKeyFile \/opt\/ssl\/${SSL_KEY_FILE}/g" ${HTTPD_CUSTOM_CONF_FOLDER}/001-ssl.conf

# Split the list of hosts
hostsArray=`echo "${BACKEND_HOSTS}" | sed "s/,/ /g"`

counter=0

cat $CONF_FRAGMENTS_FOLDER/010-balancer-begin.conf > $HTTPD_CUSTOM_CONF_FOLDER/010-balancer.conf

for host in $hostsArray
do
	counter=$((counter+1))
	echo "    BalancerMember \"${BACKEND_PROTOCOL}://${host}:${BACKEND_PORT}\" route=$counter" >> $HTTPD_CUSTOM_CONF_FOLDER/010-balancer.conf
done

cat $CONF_FRAGMENTS_FOLDER/010-balancer-end.conf >> $HTTPD_CUSTOM_CONF_FOLDER/010-balancer.conf

# Continue with the usual startup
/usr/local/bin/define-server-name-and-start.sh
