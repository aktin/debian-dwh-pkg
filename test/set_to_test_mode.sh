#! /bin/bash

readonly RESOURCES=$(pwd)/resources

apt-get install -y jq

echo "Move python test scripts to /var/lib/aktin"
cp $RESOURCES/scripts/* /var/lib/aktin/import-scripts/

echo "Adjust aktin.properties"
sed -i 's|import.script.timeout=.*|import.script.timeout=35000|'  /opt/wildfly/standalone/configuration/aktin.properties
sed -i 's|broker.uris=.*|broker.uris=http://10.0.2.2:8080/broker/|'  /opt/wildfly/standalone/configuration/aktin.properties # default ip for VM with NAT
sed -i 's|broker.intervals=.*|broker.intervals=PT30S|'  /opt/wildfly/standalone/configuration/aktin.properties
sed -i 's|broker.keys=.*|broker.keys=xxxApiKey890|'  /opt/wildfly/standalone/configuration/aktin.properties

service wildfly restart
