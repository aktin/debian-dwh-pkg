# --------------------------------------
# Dockerfile for PostgreSQL with i2b2 and AKTIN Database Initialization
# Version:      1.0
# Author:       skurka@ukaachen.de, shuening@ukaachen.de, akombeiz@ukaachen.de
# Date:         29 Oct 24
# Purpose:      Dockerfile to initialize a PostgreSQL database with i2b2 and AKTIN schemas and data, including custom SQL scripts for
#               setup and updates.
# --------------------------------------

FROM __BASE_IMAGE__

LABEL maintainer="AKTIN IT <it-support@aktin.org>"

# Copy SQL scripts into directory for custom SQL scripts
COPY ./sql/*sql /sql.d/

# Concatenate custom SQL scripts into a single initialization script
RUN cat /sql.d/addon_i2b2crcdata.concept_dimension.sql \
        /sql.d/addon_i2b2metadata.sql \
        /sql.d/01_convert_zipcodes_to_str.sql \
        /sql.d/02_add_missing_p21_dates.sql \
        /sql.d/aktin_init.sql >> /docker-entrypoint-initdb.d/init.sql && \
    rm /sql.d/addon_i2b2crcdata.concept_dimension.sql \
       /sql.d/addon_i2b2metadata.sql \
       /sql.d/01_convert_zipcodes_to_str.sql \
       /sql.d/02_add_missing_p21_dates.sql \
       /sql.d/aktin_init.sql
