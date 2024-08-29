FROM __BASEIMAGE__

WORKDIR /opt/wildfly
COPY ./dwh-j2ee-*.ear ./standalone/deployments/
COPY ./import-scripts /var/lib/aktin/import-scripts

COPY ./wildfly_cli/*.cli .
RUN ./bin/jboss-cli.sh --file=./config.cli
RUN rm ./*.cli

COPY ./aktin.properties /etc/aktin/
RUN ln -sf /etc/aktin/aktin.properties ./standalone/configuration/

USER root
RUN rm -rf ./standalone/configuration/standalone_xml_history/current/*
RUN mkdir -p /var/lib/aktin/import
RUN chown -R wildfly:wildfly ./standalone/deployments /etc/aktin /var/lib/aktin

USER wildfly
