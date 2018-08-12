#!/bin/bash

DOCKER_MAC_HOST="docker.for.mac.localhost"
DOCKER_WINDOWS_HOST="docker.for.win.localhost"

CONF_FRAGMENTS_FOLDER=/httpd-conf-fragments
HTTPD_DEFAULT_CONF_FOLDER=/etc/httpd/default.conf.d
HTTPD_CUSTOM_CONF_FOLDER=/etc/httpd/conf.d
HTTPD_FALLBACK_CONF_FOLDER=/etc/httpd/fallback.conf.d

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

sed -i -e "s/SSLCertificateFile .*/SSLCertificateFile \/opt\/ssl\/${SSL_CERTIFICATE_FILE}/g" ${HTTPD_DEFAULT_CONF_FOLDER}/010-ssl.conf
sed -i -e "s/SSLCertificateKeyFile .*/SSLCertificateKeyFile \/opt\/ssl\/${SSL_KEY_FILE}/g" ${HTTPD_DEFAULT_CONF_FOLDER}/010-ssl.conf

if [ "${SSL_CA_CERTIFICATE_FILE}" != "" ]
then
	sed -i -e "s/#SSLCACertificateFile .*/SSLCACertificateFile \/opt\/ssl\/${SSL_CA_CERTIFICATE_FILE}/g" ${HTTPD_DEFAULT_CONF_FOLDER}/010-ssl.conf
fi

# Split the list of hosts
hostsArray=`echo "${BACKEND_HOSTS}" | sed "s/,/ /g"`

counter=0

cat $CONF_FRAGMENTS_FOLDER/010-balancer-begin.conf >> $HTTPD_FALLBACK_CONF_FOLDER/001-http-backend.conf
cat $CONF_FRAGMENTS_FOLDER/010-balancer-begin.conf >> $HTTPD_FALLBACK_CONF_FOLDER/002-https-backend.conf

for host in $hostsArray
do
	counter=$((counter+1))

	if [ $host == 'localhost' ]
	then
		# localhost must be resolved in a special way to point to the host instead of the container itself

		ip=$(sh -c "timeout 1s ping -c1 $DOCKER_MAC_HOST" 2>&1)

#		echo "Ping result for '$DOCKER_MAC_HOST': $ip"

		if [ "$?" -eq 0 ]
		then
			ip=$(echo "$ip" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n1)
		else
			ip=""
		fi

		if [ "$ip" == "" ]
		then
			ip=$(sh -c "timeout 1s ping -c1 $DOCKER_WINDOWS_HOST" 2>&1)

#			echo "Ping result for '$DOCKER_WINDOWS_HOST': $ip"

			if [ "$?" -eq 0 ]
			then
				ip=$(echo "$ip" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n1)
			else
				ip=""
			fi
		else
			echo "IP resolved for $DOCKER_MAC_HOST: $ip"
		fi

		if [ "$ip" == "" ]
		then
			ip=$(ip r | grep ^default | cut -d" " -f3)
		else
			echo "IP resolved for $DOCKER_WINDOWS_HOST: $ip"
		fi

		if [ "$ip" == "" ]
		then
			resolvedHost=$host
		else
			echo "IP resolved for 'localhost': $ip"
		fi

		resolvedHost=$ip
	else
		resolvedHost=$host
	fi;

	echo "    BalancerMember \"${BACKEND_PROTOCOL}://${resolvedHost}:${BACKEND_PORT}\" route=$counter" >> $HTTPD_FALLBACK_CONF_FOLDER/001-http-backend.conf
	echo "    BalancerMember \"${BACKEND_PROTOCOL}://${resolvedHost}:${BACKEND_PORT}\" route=$counter" >> $HTTPD_FALLBACK_CONF_FOLDER/002-https-backend.conf
done

cat $CONF_FRAGMENTS_FOLDER/010-balancer-end.conf >> $HTTPD_FALLBACK_CONF_FOLDER/001-http-backend.conf
cat $CONF_FRAGMENTS_FOLDER/010-balancer-end.conf >> $HTTPD_FALLBACK_CONF_FOLDER/002-https-backend.conf

if [ "${SERVER_FORCE_HTTPS}" == "true" ]
then
	rm -f $HTTPD_FALLBACK_CONF_FOLDER/001-http-backend.conf
else
	rm -f $HTTPD_FALLBACK_CONF_FOLDER/001-http-redirection.conf
fi

# Continue with the usual startup
httpd -DFOREGROUND
