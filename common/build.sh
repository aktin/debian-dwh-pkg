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

deploy_apache2_proxy_configuration() {
  local dir_apache2_conf="${1}"
  local host_wildfly="${2}"

  mkdir -p "${DIR_BUILD}${dir_apache2_conf}"
  sed -e "s/__WILDFLY_HOST__/${host_wildfly}/g" "${DIR_RESOURCES}/httpd/aktin-j2ee-reverse-proxy.conf" > "${DIR_BUILD}${dir_apache2_conf}/aktin-j2ee-reverse-proxy.conf"
}

deploy_aktin_properties() {
  local dir_aktin_properties="${1}"

  mkdir -p "${DIR_BUILD}${dir_aktin_properties}"
  cp "${DIR_RESOURCES}/aktin.properties" "${DIR_BUILD}${dir_aktin_properties}/"
}

download_and_deploy_aktin_import_scripts() {
  local dir_import_scripts="${1}"

  mkdir -p "${DIR_BUILD}${dir_import_scripts}"
  deploy_p21_import_script "${DIR_DOWNLOADS}"

  cp -r "${DIR_DOWNLOADS}/import-scripts" "${DIR_BUILD}${dir_import_scripts}"
}

deploy_p21_import_script() {
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

copy_sql_scripts() {
  local dir_db="${1}"

  mkdir -p "$(dirname "${DIR_BUILD}${dir_db}")"
  cp -r "${DIR_RESOURCES}/sql" "${DIR_BUILD}${dir_db}"
}

copy_sql_update_scripts() {
  local dir_db_update="${1}"

  mkdir -p "$(dirname "${DIR_BUILD}${dir_db_update}")"
  cp -r "${DIR_RESOURCES}/database-updates" "${DIR_BUILD}${dir_db_update}"
}

copy_wildfly_config() {
  local dir_wildfly_config="${1}"

  mkdir -p "$(dirname "${DIR_BUILD}${dir_wildfly_config}")"
  local config_cli_template="${DIR_RESOURCES}/wildfly/config.cli"
  local config_cli_processed="${DIR_BUILD}${dir_wildfly_config}/aktin_config.cli"

  # Replace the placeholder in the config.cli file
  sed "s/__POSTGRES_JDBC_VERSION__/${VERSION_POSTGRES_JDBC}/g" "${config_cli_template}" > "${config_cli_processed}"
}
