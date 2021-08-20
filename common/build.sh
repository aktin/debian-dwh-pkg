#!/bin/bash
set -euo pipefail

# Check if variables are empty
if [ -z "${PACKAGE}" ]; then echo "\$PACKAGE is empty."; exit 1; fi
if [ -z "${VERSION}" ]; then echo "\$VERSION is empty."; exit 1; fi
if [ -z "${DBUILD}" ]; then echo "\$DBUILD is empty."; exit 1; fi

# Superdirectory this script is located in + /resources
DRESOURCES="$( cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" &> /dev/null && pwd )/resources"

set -a
. "${DRESOURCES}/versions"
set +a

function download_dwh_j2ee() {
	DWILDFLYDEPLOYMENTS="${1}"

	mkdir -p "${DBUILD}${DWILDFLYDEPLOYMENTS}"
	mvn dependency:get -DremoteRepositories="https://www.aktin.org/software/repo/" -Dartifact="org.aktin.dwh:dwh-j2ee:${VDWH_J2EE}:ear" -Ddest="${DBUILD}${DWILDFLYDEPLOYMENTS}/"
}

function config_apache2_proxy() {
	DAPACHE2CONF="${1}"
	WILDFLYHOST="${2}"

	mkdir -p "${DBUILD}${DAPACHE2CONF}"
	sed -e "s/__WILDFLYHOST__/${WILDFLYHOST}/g" "${DRESOURCES}/aktin-j2ee-reverse-proxy.conf" >"${DBUILD}${DAPACHE2CONF}/aktin-j2ee-reverse-proxy.conf"
}

function create_aktin_dir() {
	DAKTINDIR="${1}"

	mkdir -p "${DBUILD}${DAKTINDIR}"
}

function move_aktin_properties() {
	DAKTINCONF="${1}"

	mkdir -p "${DBUILD}${DAKTINCONF}"
	cp "${DRESOURCES}/aktin.properties" "${DBUILD}${DAKTINCONF}/"
}

function move_aktin_importscripts() {
	DAKTINIMPORTSCRIPTS="${1}"

	mkdir -p "$(dirname "${DBUILD}${DAKTINIMPORTSCRIPTS}")"
	cp -r "${DRESOURCES}/import-scripts" "${DBUILD}${DAKTINIMPORTSCRIPTS}"
}

function move_database_for_postinstall() {
	DDBPOSTINSTALL="$1"

	mkdir -p "$(dirname "${DBUILD}${DDBPOSTINSTALL}")"
	cp -r "${DRESOURCES}/database" "${DBUILD}${DDBPOSTINSTALL}"
}

function move_database_update_for_postinstall() {
	DDBUPDATEPOSTINSTALL="$1"

	mkdir -p "$(dirname "${DBUILD}${DDBUPDATEPOSTINSTALL}")"
	cp -r "${DRESOURCES}/database-update" "${DBUILD}${DDBUPDATEPOSTINSTALL}"
}

function move_datasource_for_postinstall() {
	DDSPOSTINSTALL="$1"

	mkdir -p "$(dirname "${DBUILD}${DDSPOSTINSTALL}")"
	cp -r "${DRESOURCES}/datasource" "${DBUILD}${DDSPOSTINSTALL}"
}

function build_linux() {
	download_dwh_j2ee "/opt/wildfly/standalone/deployments"
	config_apache2_proxy "/etc/apache2/conf-available" "localhost"
	create_aktin_dir "/var/lib/aktin"
	create_aktin_dir "/var/lib/aktin/import"
	move_aktin_properties "/etc/aktin"
	move_aktin_importscripts "/var/lib/aktin/import-scripts"
	move_database_for_postinstall "/usr/share/${PACKAGE}/database"
	move_database_update_for_postinstall "/usr/share/${PACKAGE}/database-update"
	move_datasource_for_postinstall "/usr/share/${PACKAGE}/datasource"
}
