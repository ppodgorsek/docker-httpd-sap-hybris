#!/bin/bash

DOCKER_MAC_HOST="docker.for.mac.localhost"
DOCKER_WINDOWS_HOST="docker.for.win.localhost"

echo "Defining the server name as: ${SERVER_NAME}"
echo "ServerName ${SERVER_NAME}" > /etc/httpd/conf.d/000-server-details.conf

echo "Backend hosts: ${BACKEND_HOSTS}"
echo "Backend port: ${BACKEND_PORT}"
echo "Backend protocol: ${BACKEND_PROTOCOL}"

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

	if [ $host == 'localhost' ]
	then
		# localhost must be resolved in a special way to point to the host instead of the container itself

		ip=$(sh -c "timeout 1s ping -c1 $DOCKER_MAC_HOST" 2>&1)

		echo "Ping result for '$DOCKER_MAC_HOST': $ip"

		if [ "$?" -eq 0 ]; then
			ip=$(echo "$ip" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n1)
			echo "IP resolved for $DOCKER_MAC_HOST: $ip"    
		else
			ip=$(sh -c "timeout 1s ping -c1 $DOCKER_WINDOWS_HOST" 2>&1)

			echo "Ping result for '$DOCKER_WINDOWS_HOST': $ip"

			if [ "$?" -eq 0 ]; then
				ip=$(echo "$ip" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n1)
				echo "IP resolved for $DOCKER_WINDOWS_HOST: $ip"
			else
				ip=$(ip r | grep ^default | cut -d" " -f3)
				echo "IP resolved for 'localhost': $ip"
			fi
		fi

		resolvedHost=$ip
	else
		resolvedHost=$host
	fi;

	echo "    BalancerMember \"${BACKEND_PROTOCOL}://${resolvedHost}:${BACKEND_PORT}\" route=$counter" >> $HTTPD_CUSTOM_CONF_FOLDER/010-balancer.conf
done

cat $CONF_FRAGMENTS_FOLDER/010-balancer-end.conf >> $HTTPD_CUSTOM_CONF_FOLDER/010-balancer.conf

# Continue with the usual startup
httpd -DFOREGROUND
