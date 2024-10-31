#!/bin/bash
#--------------------------------------
# Script Name:  build.sh
# Version:      1.1
# Author:       skurka@ukaachen.de, shuening@ukaachen.de, akombeiz@ukaachen.de
# Date:         31 Oct 24
# Purpose:      This script builds the aktin-notaufnahme-dwh package by preparing the environment, copying necessary files, and creating the
#               Debian package.
#--------------------------------------

# what is need from i2b2 package

# config from maintainer script
# templates from maintainer script
# helper.sh

set -euo pipefail

readonly PACKAGE_NAME="aktin-notaufnahme-dwh"
readonly I2B2_PACKAGE_DEPENDENCY="$(echo "${PACKAGE_NAME}" | awk -F '-' '{print $1"-"$2"-i2b2"}')"

# Determine PACKAGE_VERSION: Use environment variable or first script argument
readonly PACKAGE_VERSION="${PACKAGE_VERSION:-${1:-}}"
if [[ -z "${PACKAGE_VERSION}" ]]; then
  echo "Error: PACKAGE_VERSION is not specified." >&2
  echo "Usage: $0 <PACKAGE_VERSION>"
  exit 1
fi

# Define relevant directories as absolute paths
readonly DIR_CURRENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly DIR_BUILD="${DIR_CURRENT}/build/${PACKAGE_NAME}_${PACKAGE_VERSION}"
readonly DIR_RESOURCES="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)/resources"
readonly DIR_DOWNLOADS="$(dirname "${DIR_RESOURCES}")/downloads"

clean_up_build_environment() {
  echo "Cleaning up previous build environment..."
  rm -rf "${DIR_BUILD}"
}

: '
init_build_environment() {
  echo "Initializing build environment..."
  set -a
  # Load version-specific variables from file
  . "${DIR_RESOURCES}/versions"
  set +a
  if [ ! -d "${DIR_BUILD}" ]; then
    mkdir -p "${DIR_BUILD}"
  fi
  if [ ! -d "${DIR_DOWNLOADS}" ]; then
    mkdir -p "${DIR_DOWNLOADS}"
  fi
}
'

#TODO fix this
download_and_copy_dwh_j2ee() {
  local dir_wildfly_deployments="${1}"

  mkdir -p "${DIR_BUILD}${dir_wildfly_deployments}"
  if [ ! -f "${DIR_DOWNLOADS}/dwh-j2ee-${AKTIN_DWH_VERSION}.ear" ]; then
    echo "Download AKTIN DWH EAR Version ${AKTIN_DWH_VERSION}"
    mvn dependency:get -DremoteRepositories="https://www.aktin.org/software/repo/" -Dartifact="org.aktin.dwh:dwh-j2ee:${AKTIN_DWH_VERSION}:ear"
    # dirty
    cp ~/".m2/repository/org/aktin/dwh/dwh-j2ee/${AKTIN_DWH_VERSION}/dwh-j2ee-${AKTIN_DWH_VERSION}.ear" "${DIR_DOWNLOADS}"
  fi

  cp "${DIR_DOWNLOADS}/dwh-j2ee-${AKTIN_DWH_VERSION}.ear" "${DIR_BUILD}${dir_wildfly_deployments}"
}

copy_apache2_proxy_config() {
  local dir_apache2_conf="${1}"

  mkdir -p "${DIR_BUILD}${dir_apache2_conf}"
  cp "${DIR_RESOURCES}/httpd/aktin-j2ee-reverse-proxy.conf" "${DIR_BUILD}${dir_apache2_conf}/aktin-j2ee-reverse-proxy.conf"
}

copy_aktin_properties() {
  local dir_aktin_properties="${1}"

  mkdir -p "${DIR_BUILD}${dir_aktin_properties}"
  cp "${DIR_RESOURCES}/aktin.properties" "${DIR_BUILD}${dir_aktin_properties}/"
}

download_p21_import_script() {
    local dir_downloads="${1}"
    local local_p21="${dir_downloads}/import-scripts/p21import.py"
    local local_version="0.0.0"

    # Check if the local p21import.py exists and extract its version
    if [ -f "${local_p21}" ]; then
        local_version=$(grep '^# @VERSION=' "${local_p21}" | sed 's/^# @VERSION=//')
    fi

    # Get the version from GitHub
    local github_p21_url="https://raw.githubusercontent.com/aktin/p21-script/main/src/p21import.py"
    local github_version=$(curl -s "${github_p21_url}" | grep '^# @VERSION=' | sed 's/^# @VERSION=//')

    # Compare versions
    if [ "${local_version}" = "${github_version}" ]; then
        # Versions are the same, do nothing
        echo "p21import.py is up to date (version ${local_version})."
    else
        # Determine if the GitHub version is newer
        if [ "$(printf '%s\n' "${local_version}" "${github_version}" | sort -V | head -n1)" = "${local_version}" ] && [ "${local_version}" != "${github_version}" ]; then
            # Local version is older, download the newer script
            mkdir -p "${dir_downloads}/import-scripts"
            echo "Updating p21import.py to version ${github_version}."
            curl -s -o "${local_p21}" "${github_p21_url}"
        else
            # Local version is newer or versions are incomparable
            echo "Local p21import.py version (${local_version}) is up-to-date or newer than GitHub version (${github_version})."
        fi
    fi
}

download_and_copy_aktin_import_scripts() {
  local dir_import_scripts="${1}"

  mkdir -p "${DIR_BUILD}${dir_import_scripts}"
  download_p21_import_script "${DIR_DOWNLOADS}"

  cp -r ${DIR_DOWNLOADS}/import-scripts/* "${DIR_BUILD}${dir_import_scripts}"
}

copy_sql_scripts() {
  local dir_db="${1}"

  mkdir -p "${DIR_BUILD}${dir_db}"
  cp -r ${DIR_RESOURCES}/sql/* "${DIR_BUILD}${dir_db}"
}

copy_wildfly_config() {
  local dir_wildfly_config="${1}"

  mkdir -p "${DIR_BUILD}${dir_wildfly_config}"
  local config_cli_template="${DIR_RESOURCES}/wildfly/config.cli"
  local config_cli_processed="${DIR_BUILD}${dir_wildfly_config}/aktin_config.cli"

  # Replace the placeholder in the config.cli file
  sed "s/__POSTGRES_JDBC_VERSION__/${POSTGRES_JDBC_VERSION}/g" "${config_cli_template}" > "${config_cli_processed}"
}

prepare_management_scripts_and_files() {
  mkdir -p "${DIR_BUILD}/DEBIAN"

  # Replace placeholders
  sed -e "s|__PACKAGE_NAME__|${PACKAGE_NAME}|g" -e "s|__PACKAGE_VERSION__|${PACKAGE_VERSION}|g" -e "s|__I2B2_PACKAGE_DEPENDENCY__|${PACKAGE_I2B2}|g" -e "s|__POSTGRESQL_PACKAGE_VERSION__|${POSTGRESQL_PACKAGE_VERSION}|g" "${DIR_CURRENT}/control" > "${DIR_BUILD}/DEBIAN/control"
  local shared_package_name=$(echo "${PACKAGE_NAME}" | awk -F '-' '{print $1"-"$2}')
  sed -e "s|__SHARED_PACKAGE__|${shared_package_name}|g" "${DIR_CURRENT}/templates" > "${DIR_BUILD}/DEBIAN/templates"
  sed -e "s|__SHARED_PACKAGE__|${shared_package_name}|g" "${DIR_CURRENT}/config" > "${DIR_BUILD}/DEBIAN/config"

  # Copy necessary scripts
  cp "${DIR_CURRENT}/preinst" "${DIR_BUILD}/DEBIAN/"
  cp "${DIR_CURRENT}/postinst" "${DIR_BUILD}/DEBIAN/"
  cp "${DIR_CURRENT}/prerm" "${DIR_BUILD}/DEBIAN/"

  # Process the postrm script by inserting SQL drop statements
  sed -e "/^__AKTIN_DROP_STATEMENT__/{r ${DIR_RESOURCES}/sql/aktin_drop.sql" -e 'd;}' "${DIR_CURRENT}/postrm" > "${DIR_BUILD}/DEBIAN/postrm"
  chmod 0755 "${DIR_BUILD}/DEBIAN/postrm"
}

build_package() {
  dpkg-deb --build "${DIR_BUILD}"
  rm -rf "${DIR_BUILD}"
}

main() {
  set -euo pipefail
  clean_up_build_environment
  #init_build_environment

  download_and_copy_dwh_j2ee "/opt/wildfly/standalone/deployments"
  copy_apache2_proxy_config "/etc/apache2/conf-available"
  copy_aktin_properties "/etc/aktin"
  download_and_copy_aktin_import_scripts "/var/lib/aktin/import-scripts"
  copy_sql_scripts "/usr/share/${PACKAGE_NAME}/sql"
  copy_sql_update_scripts "/usr/share/${PACKAGE_NAME}/database-updates"
  copy_wildfly_config "/opt/wildfly/bin"

  prepare_package_environment
  prepare_management_scripts_and_files
  build_package
}

main
