#!/bin/bash
#--------------------------------------
# Script Name:  common/build.sh
# Version:      1.0
# Author:       skurka@ukaachen.de, shuening@ukaachen.de, akombeiz@ukaachen.de
# Date:         28 Oct 24
# Purpose:      This script builds the aktin-notaufnahme-dwh package by preparing the environment, copying necessary files, and creating the
#               Debian package.
#--------------------------------------

set -euo pipefail

readonly PACKAGE="aktin-notaufnahme-dwh"

# Determine VERSION: Use environment variable or first script argument
VERSION="${VERSION:-${1:-}}"
if [[ -z "${VERSION}" ]]; then
  echo "Error: VERSION is not specified." >&2
  echo "Usage: $0 <version>"
  exit 1
fi
readonly VERSION

# Get the directory where this script is located
readonly DIR_CURRENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly DIR_BUILD="${DIR_CURRENT}/build/${PACKAGE}_${VERSION}"
readonly PACKAGE_I2B2="$(echo "${PACKAGE}" | awk -F '-' '{print $1"-"$2"-i2b2"}')"

load_common_files_and_prepare_environment() {
  source "$(dirname "${DIR_CURRENT}")/common/build.sh"
  clean_up_build_environment
  init_build_environment
}

prepare_package_environment() {
  download_and_copy_dwh_j2ee "/opt/wildfly/standalone/deployments"
  copy_apache2_proxy_config "/etc/apache2/conf-available" "localhost"
  copy_aktin_properties "/etc/aktin"
  download_and_copy_aktin_import_scripts "/var/lib/aktin/import-scripts"
  copy_sql_scripts "/usr/share/${PACKAGE}/sql"
  copy_sql_update_scripts "/usr/share/${PACKAGE}/database-updates"
  copy_wildfly_config "/opt/wildfly/bin"
}

prepare_management_scripts_and_files() {
  mkdir -p "${DIR_BUILD}/DEBIAN"

  # Replace placeholders in the control file
  sed -e "s/__PACKAGE__/${PACKAGE}/g" -e "s/__VERSION__/${VERSION}/g" -e "s/__I2B2_PACKAGE_DEPENDENCY__/${PACKAGE_I2B2}" -e "s/__POSTGRESQL_VERSION__/${VERSION_POSTGRESQL}/g" "${DIR_CURRENT}/control" > "${DIR_BUILD}/DEBIAN/control"

  # Prepare .deb management scripts and control files
  sed -e "s/__I2B2_SHARED__/$(echo "${PACKAGE}" | awk -F '-' '{print $1"-"$2}')/g" -e "s/__PACKAGE__/${PACKAGE}/g" "${DIR_CURRENT}/templates" > "${DIR_BUILD}/DEBIAN/templates"

  # Copy necessary scripts
  cp "${DIR_CURRENT}/config" "${DIR_BUILD}/DEBIAN/"
  cp "${DIR_CURRENT}/preinst" "${DIR_BUILD}/DEBIAN/"
  cp "${DIR_CURRENT}/postinst" "${DIR_BUILD}/DEBIAN/"
  cp "${DIR_CURRENT}/prerm" "${DIR_BUILD}/DEBIAN/"

  # Process the postrm script by inserting SQL drop statements
  sed -e "/^__AKTIN_DROP__/{r ${DIR_RESOURCES}/sql/aktin_drop.sql" -e 'd;}' "${DIR_CURRENT}/postrm" > "${DIR_BUILD}/DEBIAN/postrm"
  chmod 0755 "${DIR_BUILD}/DEBIAN/postrm"
}

build_package() {
  dpkg-deb --build "${DIR_BUILD}"
  rm -rf "${DIR_BUILD}"
}

main() {
  set -euo pipefail
  load_common_files_and_prepare_environment
  prepare_package_environment
  prepare_management_scripts_and_files
  build_package
}

main
