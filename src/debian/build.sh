#!/bin/bash
#--------------------------------------
# Script Name:  build.sh
# Version:      1.2
# Author:       skurka@ukaachen.de, shuening@ukaachen.de, akombeiz@ukaachen.de
# Date:         05 Dec 24
# Purpose:      Builds the AKTIN Emergency Department Data Warehouse (DWH) package. Downloads required artifacts, prepares configuration files and
#               creates the Debian package that extends the i2b2 installation.
#--------------------------------------

set -euo pipefail

readonly PACKAGE_NAME="aktin-notaufnahme-dwh"
readonly TRIGGER_PREFIX="aktin"

CLEANUP=false
SKIP_BUILD=false
FULL_CLEAN=false

usage() {
  echo "Usage: $0 [--cleanup] [--skip-deb-build] [--full-clean]" >&2
  echo "  --cleanup          Optional: Remove build directory after package creation" >&2
  echo "  --skip-deb-build   Optional: Skip the debian package build step" >&2
  echo "  --full-clean       Optional: Remove build and downloads directories before starting" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --cleanup)
      CLEANUP=true
      shift
      ;;
    --skip-deb-build)
      SKIP_BUILD=true
      shift
      ;;
    --full-clean)
      FULL_CLEAN=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Error: Unexpected argument '$1'" >&2
      usage
      ;;
  esac
done

# Define relevant directories as absolute paths
readonly DIR_DEBIAN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DIR_SRC="$(dirname "${DIR_DEBIAN}")"
readonly DIR_RESOURCES="${DIR_SRC}/resources"
readonly DIR_DOWNLOADS="${DIR_SRC}/downloads"

# Load version-specific variables from file
set -a
. "${DIR_RESOURCES}/versions"
set +a
readonly DIR_BUILD="${DIR_SRC}/build/${PACKAGE_NAME}_${PACKAGE_VERSION}"

clean_up_build_environment() {
  echo "Cleaning up previous build environment..."
  rm -rf "${DIR_BUILD}"
  if [[ "${FULL_CLEAN}" == true ]]; then
    echo "Performing full clean..."
    rm -rf "${DIR_SRC}/build"
    rm -rf "${DIR_DOWNLOADS}"
  fi
}

init_build_environment() {
  echo "Initializing build environment..."
  if [[ ! -d "${DIR_BUILD}" ]]; then
    mkdir -p "${DIR_BUILD}"
  fi
  if [[ ! -d "${DIR_DOWNLOADS}" ]]; then
    mkdir -p "${DIR_DOWNLOADS}"
  fi
}

copy_apache2_proxy_config() {
  local dir_apache2_conf="${1}"
  echo "Copying Apache proxy configuration..."
  mkdir -p "${DIR_BUILD}${dir_apache2_conf}"
  cp "${DIR_RESOURCES}/httpd/aktin-j2ee-reverse-proxy.conf" "${DIR_BUILD}${dir_apache2_conf}"
}

#TODO fix this
download_and_copy_dwh_j2ee() {
  local dir_wildfly_deployments="${1}"
  local ear_file="dwh-j2ee-${AKTIN_DWH_VERSION}.ear"
  echo "Downloading DWH application..."

  mkdir -p "${DIR_BUILD}${dir_wildfly_deployments}"
  if [[ -f "${DIR_DOWNLOADS}/${ear_file}" ]]; then
    echo "Using cached DWH EAR"
  else
    mvn dependency:get -DremoteRepositories="https://www.aktin.org/software/repo/" -Dartifact="org.aktin.dwh:dwh-j2ee:${AKTIN_DWH_VERSION}:ear"
    # dirty
    cp ~/".m2/repository/org/aktin/dwh/dwh-j2ee/${AKTIN_DWH_VERSION}/${ear_file}" "${DIR_DOWNLOADS}"
  fi

  cp "${DIR_DOWNLOADS}/${ear_file}" "${DIR_BUILD}${dir_wildfly_deployments}"
}

download_p21_import_script() {
  local dir_downloads="${1}"
  local local_p21="${dir_downloads}/import-scripts/p21import.py"
  local local_version="0.0.0"

  # Check if the local p21import.py exists and extract its version
  if [[ -f "${local_p21}" ]]; then
    local_version="$(grep '^# @VERSION=' "${local_p21}" | sed 's/^# @VERSION=//')"
  fi
  # Get the first (latest) tag name directly from the repo
  local tags_url="https://api.github.com/repos/aktin/p21-script/tags"
  local latest_tag="$(curl -s "${tags_url}" | grep -m1 '"name":' | cut -d'"' -f4 | sed 's/^v//')"
  if [[ -z "${latest_tag}" ]]; then
     echo "Error: Failed to fetch latest tag from GitHub" >&2
     return 1
  fi
  # Construct the URL for the latest tag version of p21import.py
  local github_p21_url="https://raw.githubusercontent.com/aktin/p21-script/v${latest_tag}/src/p21import.py"
  local github_version="$(curl -s "${github_p21_url}" | grep '^# @VERSION=' | sed 's/^# @VERSION=//')"

  if [[ "${local_version}" = "${github_version}" ]]; then
    echo "P21 import script is up to date (version ${local_version})."
  else
    if [[ "$(printf '%s\n' "${local_version}" "${github_version}" | sort -V | head -n1)" = "${local_version}" ]] && [[ "${local_version}" != "${github_version}" ]]; then
      # Local version is older, download the newer script
      mkdir -p "${dir_downloads}/import-scripts"
      echo "Downloading P21 import script with version ${github_version}."
      curl -s -o "${local_p21}" "${github_p21_url}"
    else
      echo "Local P21 import script version (${local_version}) is up-to-date or newer than GitHub version (${github_version})."
    fi
  fi
}

download_and_copy_aktin_import_scripts() {
  local dir_import_scripts="${1}"
  echo "Preparing AKTIN import scripts..."
  mkdir -p "${DIR_BUILD}${dir_import_scripts}"
  download_p21_import_script "${DIR_DOWNLOADS}"
  cp "${DIR_DOWNLOADS}"/import-scripts/* "${DIR_BUILD}${dir_import_scripts}"
}

copy_aktin_properties() {
  local dir_aktin_properties="${1}"
  echo "Copying AKTIN properties..."
  mkdir -p "${DIR_BUILD}${dir_aktin_properties}"
  cp "${DIR_RESOURCES}/aktin.properties" "${DIR_BUILD}${dir_aktin_properties}"
}

copy_wildfly_config() {
  local dir_wildfly_config="${1}"
  echo "Copying WildFly configuration..."
  mkdir -p "${DIR_BUILD}${dir_wildfly_config}"
  cp "${DIR_RESOURCES}/wildfly/"* "${DIR_BUILD}${dir_wildfly_config}"
}

copy_sql_scripts() {
  local dir_db="${1}"
  echo "Copying SQL scripts..."
  mkdir -p "${DIR_BUILD}${dir_db}"
  cp -r "${DIR_RESOURCES}/sql/"* "${DIR_BUILD}${dir_db}"
}

prepare_management_scripts_and_files() {
  local i2b2_package_name="$(echo "${PACKAGE_NAME}" | awk -F '-' '{print $1"-"$2"-i2b2"}')"
  echo "Preparing Debian package management files..."
  mkdir -p "${DIR_BUILD}/DEBIAN"

  # Replace placeholders
  sed -e "s|__PACKAGE_NAME__|${PACKAGE_NAME}|g" -e "s|__PACKAGE_VERSION__|${PACKAGE_VERSION}|g" -e "s|__I2B2_PACKAGE_NAME__|${i2b2_package_name}|g" -e "s|__I2B2_PACKAGE_DEPENDENCY__|${I2B2_PACKAGE_DEPENDENCY}|g" "${DIR_DEBIAN}/control" > "${DIR_BUILD}/DEBIAN/control"
  sed -e "s|__I2B2_PACKAGE_NAME__|${i2b2_package_name}|g" "${DIR_DEBIAN}/preinst" > "${DIR_BUILD}/DEBIAN/preinst"
  sed -e "s|__I2B2_PACKAGE_NAME__|${i2b2_package_name}|g" "${DIR_DEBIAN}/prerm" > "${DIR_BUILD}/DEBIAN/prerm"
  sed -e "s|__I2B2_PACKAGE_NAME__|${i2b2_package_name}|g" -e "s|__TRIGGER_PREFIX__|${TRIGGER_PREFIX}|g" "${DIR_DEBIAN}/postinst" > "${DIR_BUILD}/DEBIAN/postinst"
  sed -e "s|__I2B2_PACKAGE_NAME__|${i2b2_package_name}|g" -e "/^__AKTIN_DROP_STATEMENT__/{r ${DIR_RESOURCES}/sql/aktin_drop.sql" -e 'd;}' "${DIR_DEBIAN}/postrm" > "${DIR_BUILD}/DEBIAN/postrm"
  sed -e "s|__TRIGGER_PREFIX__|${TRIGGER_PREFIX}|g" "${DIR_DEBIAN}/triggers" > "${DIR_BUILD}/DEBIAN/triggers"

  # Set proper executable permissions
  chmod 0755 "${DIR_BUILD}/DEBIAN/"*
}

build_package() {
  if [[ "${SKIP_BUILD}" == false ]]; then
    echo "Building Debian package..."
    dpkg-deb --build "${DIR_BUILD}"
    if [[ "${CLEANUP}" == true ]]; then
      echo "Cleaning up build directory..."
      rm -rf "${DIR_BUILD}"
    fi
  else
    echo "Debian build skipped"
  fi
}

main() {
  set -euo pipefail
  clean_up_build_environment
  init_build_environment
  copy_apache2_proxy_config "/etc/apache2/conf-available"
  download_and_copy_dwh_j2ee "/opt/wildfly/standalone/deployments"
  download_and_copy_aktin_import_scripts "/var/lib/aktin/import-scripts"
  copy_aktin_properties "/etc/aktin"
  copy_wildfly_config "/opt/wildfly/bin"
  copy_sql_scripts "/usr/share/${PACKAGE_NAME}/sql"
  prepare_management_scripts_and_files
  build_package
}

main
