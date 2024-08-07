#!/bin/bash
set -euo pipefail

PACKAGE="aktin-notaufnahme-dwh"

# Required parameter
VERSION="${1}"

# Optional parameter
FULL="${2}"

# Check if variables are empty
if [ -z "${VERSION}" ]; then echo "\$VERSION is empty."; exit 1; fi

# Directory this script is located in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DBUILD="${DIR}/build"

# Cleanup
rm -rf "${DIR}/build"

export I2B2IMAGENAMESPACE="$(echo "${PACKAGE}" | awk -F '-' '{print "ghcr.io/"$1"/"$2"-i2b2-"}')"
export DWHIMAGENAMESPACE="$(echo "${PACKAGE}" | awk -F '-' '{print "ghcr.io/"$1"/"$2"-dwh-"}')"

# Load common linux files
. "$(dirname "${DIR}")/common/build.sh"


# Prepare wildfly docker
mkdir -p "${DBUILD}/wildfly"
sed -e "s|__BASEIMAGE__|${I2B2IMAGENAMESPACE}wildfly|g" "${DIR}/wildfly/Dockerfile" >"${DBUILD}/wildfly/Dockerfile"
download_dwh_j2ee "/wildfly"
copy_aktin_properties "/wildfly"
copy_aktin_importscripts "/wildfly"
copy_wildfly_config_for_postinstall "/wildfly"

# Prepapare postgresql docker
mkdir -p "${DBUILD}/database"
sed -e "s|__BASEIMAGE__|${I2B2IMAGENAMESPACE}database|g" "${DIR}/database/Dockerfile" >"${DBUILD}/database/Dockerfile"
copy_database_for_postinstall "/database/sql"
copy_database_update_for_postinstall "/database/sql"

# Prepare apache2 docker
mkdir -p "${DBUILD}/httpd"
sed -e "s|__BASEIMAGE__|${I2B2IMAGENAMESPACE}httpd|g" "${DIR}/httpd/Dockerfile" >"${DBUILD}/httpd/Dockerfile"
config_apache2_proxy "/httpd" "wildfly"

# Run docker-compose
if [ "${FULL}" = "full" ]; then
	cwd="$(pwd)"
	cd "${DIR}"
	docker compose build
	cd "${cwd}"
fi
