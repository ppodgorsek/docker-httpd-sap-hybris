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

	if [ $host == 'localhost' ]
	then
		# localhost must be resolved in a special way to point to the host instead of the container itself

		if [[ $(ping -c1 docker.for.win.localhost) ]]
		then
			echo "Resolving 'localhost' as 'docker.for.win.localhost'";
			resolvedHost="docker.for.win.localhost"
		elif [[ $(ping -c1 docker.for.mac.localhost) ]]
			echo "Resolving 'localhost' as 'docker.for.mac.localhost'";
                        resolvedHost="docker.for.mac.localhost"
		else
			echo "Resolving 'localhost' as itself";
			resolvedHost=$host
		fi
	else
		resolvedHost=$host
	fi;

	echo "    BalancerMember \"${BACKEND_PROTOCOL}://${resolvedHost}:${BACKEND_PORT}\" route=$counter" >> $HTTPD_CUSTOM_CONF_FOLDER/010-balancer.conf
done

cat $CONF_FRAGMENTS_FOLDER/010-balancer-end.conf >> $HTTPD_CUSTOM_CONF_FOLDER/010-balancer.conf

# Continue with the usual startup
/usr/local/bin/define-server-name-and-start.sh
