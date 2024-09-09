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
RUN apt update
RUN apt install locales r-base-core r-cran-lattice r-cran-xml r-cran-tidyverse python3 python3-pandas python3-numpy python3-requests python3-sqlalchemy python3-psycopg2 python3-postgresql python3-zipp python3-plotly python3-gunicorn -y

# Generate and set the German locale
RUN locale-gen de_DE.UTF-8
ENV LANG de_DE.UTF-8
ENV LANGUAGE de_DE:de
ENV LC_ALL de_DE.UTF-8

USER wildfly
