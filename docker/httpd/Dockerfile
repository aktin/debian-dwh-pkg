FROM __BASEIMAGE__
COPY ./aktin-j2ee-reverse-proxy.conf /etc/apache2/conf-available/aktin-j2ee-reverse-proxy.conf
RUN a2enmod proxy_http
RUN a2enconf aktin-j2ee-reverse-proxy
