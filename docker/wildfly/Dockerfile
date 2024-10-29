# --------------------------------------
# Dockerfile for WildFly with AKTIN DWH Deployment
# Version:      1.0
# Author:       skurka@ukaachen.de, shuening@ukaachen.de, akombeiz@ukaachen.de
# Date:         29 Oct 24
# Purpose:      Dockerfile to build a pre-configured WildFly server with AKTIN DWH deployment and necessary dependencies for data import scripts.
# --------------------------------------

FROM __BASE_IMAGE__

LABEL maintainer="AKTIN IT <it-support@aktin.org>"

WORKDIR /opt/wildfly

# Copy DWH application and import scripts to the appropriate deployment and library directories
COPY ./dwh-j2ee-*.ear ./standalone/deployments/
COPY ./import-scripts /var/lib/aktin/import-scripts

# Copy WildFly CLI configuration files and run configuration commands
COPY ./aktin_config.cli ./bin/
RUN ./bin/jboss-cli.sh --file=./bin/aktin_config.cli

# Copy AKTIN configuration properties to system configuration directory
COPY ./aktin.properties /etc/aktin/
RUN ln -sf /etc/aktin/aktin.properties ./standalone/configuration/

# Switch to root user for installing dependencies and setting permissions
USER root

# Clean up old configuration history to reduce image size
RUN rm -rf ./standalone/configuration/standalone_xml_history/current/*

# Prepare directories and set permissions for AKTIN data imports
RUN mkdir -p /var/lib/aktin/import && \
    chown -R wildfly:wildfly ./standalone/deployments /etc/aktin /var/lib/aktin

# Install necessary dependencies for data processing scripts
RUN apt update && \
    apt install -y locales \
                   r-base-core \
                   r-cran-lattice \
                   r-cran-xml \
                   r-cran-tidyverse \
                   python3 \
                   python3-pandas \
                   python3-numpy \
                   python3-requests \
                   python3-sqlalchemy \
                   python3-psycopg2 \
                   python3-postgresql \
                   python3-zipp \
                   python3-plotly \
                   python3-gunicorn && \
    rm -rf /var/lib/apt/lists/*

# Generate and set the German locale for the system
RUN locale-gen de_DE.UTF-8
ENV LANG de_DE.UTF-8
ENV LANGUAGE de_DE:de
ENV LC_ALL de_DE.UTF-8

# Switch back to WildFly user for enhanced security
USER wildfly
