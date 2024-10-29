# --------------------------------------
# Dockerfile for Apache with PHP and AKTIN Reverse Proxy Configuration
# Version:      1.0
# Author:       skurka@ukaachen.de, shuening@ukaachen.de, akombeiz@ukaachen.de
# Date:         29 Oct 24
# Purpose:      Dockerfile to set up an Apache server with PHP and enable the necessary modules and configurations for AKTIN reverse proxy.
# --------------------------------------

FROM __BASE_IMAGE__

LABEL maintainer="AKTIN IT <it-support@aktin.org>"

# Enable Apache mod_rewrite for URL rewriting
RUN a2enmod rewrite

# Install required PHP extensions for database interaction
RUN docker-php-ext-install pdo pdo_mysql

# Copy the AKTIN reverse proxy configuration file to Apache's conf-available directory
COPY ./aktin-j2ee-reverse-proxy.conf /etc/apache2/conf-available/aktin-j2ee-reverse-proxy.conf

# Enable Apache proxy_http module and activate the AKTIN reverse proxy configuration
RUN a2enmod proxy_http && a2enconf aktin-j2ee-reverse-proxy
