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

function dwh_j2ee() {
	DWILDFLYDEPLOYMENTS="${1}"
	RAKTIN="https://www.aktin.org/software/repo/org/aktin/dwh/dwh-j2ee"

	mkdir -p "${DBUILD}${DWILDFLYDEPLOYMENTS}"
	wget -O "${DBUILD}${DWILDFLYDEPLOYMENTS}/dwh-j2ee-${VDWH_J2EE}.ear" "${RAKTIN}/${VDWH_J2EE}/dwh-j2ee-${VDWH_J2EE}.ear"
}

function aktin_dir() {
	DAKTINDIR="${1}"

	mkdir -p "${DBUILD}${DAKTINDIR}"
}

function aktin_properties() {
	DAKTINCONF="${1}"

	mkdir -p "${DBUILD}${DAKTINCONF}"
	cp "${DRESOURCES}/aktin.properties" "${DBUILD}${DAKTINCONF}/"
}

function aktin_importscripts() {
	DAKTINIMPORTSCRIPTS="${1}"

	mkdir -p "$(dirname "${DBUILD}${DAKTINIMPORTSCRIPTS}")"
	cp -r "${DRESOURCES}/import-scripts" "${DBUILD}${DAKTINIMPORTSCRIPTS}"
}

function database_postinstall() {
	DDBPOSTINSTALL="$1"

	mkdir -p "$(dirname "${DBUILD}${DDBPOSTINSTALL}")"
	cp -r "${DRESOURCES}/database" "${DBUILD}${DDBPOSTINSTALL}"
}

function datasource_postinstall() {
	DDSPOSTINSTALL="$1"

	mkdir -p "$(dirname "${DBUILD}${DDSPOSTINSTALL}")"
	cp -r "${DRESOURCES}/datasource" "${DBUILD}${DDSPOSTINSTALL}"
}

function build_linux() {
	dwh_j2ee "/opt/wildfly/standalone/deployments"
	aktin_properties "/etc/aktin"
	aktin_dir "/var/lib/aktin"
	aktin_importscripts "/var/lib/aktin/import-scripts"
	aktin_dir "/var/lib/aktin/import"
	aktin_dir "/var/lib/aktin/update"
	database_postinstall "/usr/share/${PACKAGE}/database"
	datasource_postinstall "/usr/share/${PACKAGE}/datasource"
}
