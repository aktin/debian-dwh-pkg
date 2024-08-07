#!/bin/bash
set -euo pipefail

PACKAGE="aktin-notaufnahme-dwh"

# Required parameter
VERSION="${1}"

# Check if variables are empty
if [ -z "${VERSION}" ]; then echo "\$VERSION is empty."; exit 1; fi

# Directory this script is located in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DBUILD="${DIR}/build/${PACKAGE}_${VERSION}"
DEPEND_I2B2="$(echo "${PACKAGE}" | awk -F '-' '{print $1"-"$2"-i2b2"}')"

# Cleanup
rm -rf "${DIR}/build"

# Load common linux files
. "$(dirname "${DIR}")/common/build.sh"

download_dwh_j2ee "/opt/wildfly/standalone/deployments"
config_apache2_proxy "/etc/apache2/conf-available" "localhost"
create_aktin_dir "/var/lib/aktin"
create_aktin_dir "/var/lib/aktin/import"
copy_aktin_properties "/etc/aktin"
copy_aktin_importscripts "/var/lib/aktin/import-scripts"
copy_database_for_postinstall "/usr/share/${PACKAGE}/database"
copy_database_update_for_postinstall "/usr/share/${PACKAGE}/database-update"
copy_datasource_for_postinstall "/usr/share/${PACKAGE}/datasource"

# Prepare .deb management scripts and control files
mkdir -p "${DBUILD}/DEBIAN"
sed -e "s/__PACKAGE__/${PACKAGE}/g" \
    -e "s/__VERSION__/${VERSION}/g" \
    -e "s/__DEPEND_I2B2__/${DEPEND_I2B2}/g" \
    "${DIR}/control" > "${DBUILD}/DEBIAN/control"
sed -e "s/__I2B2_SHARED__/$(echo "${PACKAGE}" | awk -F '-' '{print $1"-"$2}')/g" \
    -e "s/__PACKAGE__/${PACKAGE}/g" \
    "${DIR}/templates" > "${DBUILD}/DEBIAN/templates"
cp "${DIR}/preinst" "${DBUILD}/DEBIAN/"
cp "${DIR}/postinst" "${DBUILD}/DEBIAN/"
cp "${DIR}/prerm" "${DBUILD}/DEBIAN/"
sed -e "/^__AKTIN_DROP__/{r ${DRESOURCES}/database/aktin_postgres_drop.sql" -e 'd;}' "${DIR}/postrm" > "${DBUILD}/DEBIAN/postrm" && chmod 0755 "${DBUILD}/DEBIAN/postrm"

dpkg-deb --build "${DBUILD}"
rm -rf "${DBUILD}"
