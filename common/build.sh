#!/bin/bash
#--------------------------------------
# Script Name:  common/build.sh
# Version:      1.0
# Author:       skurka@ukaachen.de, shuening@ukaachen.de, akombeiz@ukaachen.de
# Date:         28 Oct 24
# Purpose:      This helper script automates the downloading, setup, and configuration of the AKTIN DWH and WildFly application server.
#               It is used by other build.sh scripts, with all paths relative to the corresponding /build folder.

set -euo pipefail

# Check if variables are empty
if [ -z "${PACKAGE}" ]; then
  echo "\$PACKAGE is empty." >&2
  exit 1
fi
if [ -z "${VERSION}" ]; then
  echo "\$VERSION is empty." >&2
  exit 1
fi
if [ -z "${DIR_BUILD}" ]; then
  echo "\$DIR_BUILD is empty." >&2
  exit 1
fi

# Superdirectory this script is located with /resources appended, namely src/resources
readonly DIR_RESOURCES="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)/resources"

# Define DIR_DOWNLOADS as an absolute path
readonly DIR_DOWNLOADS="$(dirname "${DIR_RESOURCES}")/downloads"

init_build_environment() {
  set -a
  . "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/versions"
  set +a
  if [ ! -d "${DIR_BUILD}" ]; then
    mkdir -p "${DIR_BUILD}"
  fi
  if [ ! -d "${DIR_DOWNLOADS}" ]; then
    mkdir "${DIR_DOWNLOADS}"
  fi
}

clean_up_build_environment() {
  rm -rf "${DIR_BUILD}"
}

#TODO fix this
download_and_deploy_dwh_j2ee() {
  local dir_wildfly_deployments="${1}"

  mkdir -p "${DBUILD}${dir_wildfly_deployments}"
  if [ ! -f "${DIR_DOWNLOADS}/dwh-j2ee-${VERSION_AKTIN_DWH_J2EE}.ear" ]; then
    echo "Download AKTIN DWH EAR Version ${VERSION_AKTIN_DWH_J2EE}"
    mvn dependency:get -DremoteRepositories="https://www.aktin.org/software/repo/" -Dartifact="org.aktin.dwh:dwh-j2ee:${VERSION_AKTIN_DWH_J2EE}:ear"
    # dirty
    cp ~/".m2/repository/org/aktin/dwh/dwh-j2ee/${VERSION_AKTIN_DWH_J2EE}/dwh-j2ee-${VERSION_AKTIN_DWH_J2EE}.ear" "${DIR_DOWNLOADS}"
  fi

  cp "${DIR_DOWNLOADS}/dwh-j2ee-${VERSION_AKTIN_DWH_J2EE}.ear" "${DIR_BUILD}${dir_wildfly_deployments}"
}

configure_apache2_proxy() {
  local dir_apache2_conf="${1}"
  local host_wildfly="${2}"

  mkdir -p "${DIR_BUILD}${dir_apache2_conf}"
  sed -e "s/__WILDFLY_HOST__/${host_wildfly}/g" "${DIR_RESOURCES}/aktin-j2ee-reverse-proxy.conf" > "${DIR_BUILD}${dir_apache2_conf}/aktin-j2ee-reverse-proxy.conf"
}

deploy_aktin_properties() {
  local dir_aktin_properties="${1}"

  mkdir -p "${DIR_BUILD}${dir_aktin_properties}"
  cp "${DIR_RESOURCES}/aktin.properties" "${DIR_BUILD}${dir_aktin_properties}/"
}

function copy_aktin_importscripts() {
	DAKTINIMPORTSCRIPTS="${1}"

	mkdir -p "$(dirname "${DBUILD}${DAKTINIMPORTSCRIPTS}")"
	cp -r "${DRESOURCES}/import-scripts" "${DBUILD}${DAKTINIMPORTSCRIPTS}"
}

function copy_database_for_postinstall() {
	DDBPOSTINSTALL="$1"

	mkdir -p "$(dirname "${DBUILD}${DDBPOSTINSTALL}")"
	cp -r "${DRESOURCES}/database" "${DBUILD}${DDBPOSTINSTALL}"
}

function copy_database_update_for_postinstall() {
	DDBUPDATEPOSTINSTALL="$1"

	mkdir -p "$(dirname "${DBUILD}${DDBUPDATEPOSTINSTALL}")"
	cp -r "${DRESOURCES}/database-update" "${DBUILD}${DDBUPDATEPOSTINSTALL}"
}

function copy_datasource_for_postinstall() {
	DDSPOSTINSTALL="$1"

	mkdir -p "$(dirname "${DBUILD}${DDSPOSTINSTALL}")"
	cp -r "${DRESOURCES}/datasource" "${DBUILD}${DDSPOSTINSTALL}"
}

function copy_wildfly_config_for_postinstall() {
	DDSPOSTINSTALL="$1"

	mkdir -p "$(dirname "${DBUILD}${DDSPOSTINSTALL}")"
	cp -r "${DRESOURCES}/wildfly_cli" "${DBUILD}${DDSPOSTINSTALL}"
}



