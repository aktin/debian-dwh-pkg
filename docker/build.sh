#!/bin/bash
#--------------------------------------
# Script Name:  build.sh
# Version:      1.0
# Author:       shuening@ukaachen.de, skurka@ukaachen.de, akombeiz@ukaachen.de
# Date:         25 Oct 24
# Purpose:
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
readonly DIR_BUILD="${DIR_CURRENT}/build"

load_common_files_and_prepare_environment() {
  source "$(dirname "${DIR_CURRENT}")/common/build.sh"
  clean_up_build_environment
  init_build_environment
}

load_docker_environment_variables() {
  if [ -f "${DIR_CURRENT}/.env" ]; then
    set -a
    . "${DIR_CURRENT}/.env"
    set +a
    export BASE_IMAGE_NAMESPACE="$(echo "${PACKAGE}" | awk -F '-' '{print "ghcr.io/"$1"/"$2"-i2b2"}')"
  else
    echo "Error: .env file not found in ${DIR_CURRENT}" >&2
    exit 1
  fi
}

prepare_wildfly_docker() {
  echo "Preparing WildFly Docker image..."
  mkdir -p "${DIR_BUILD}/wildfly"
  sed -e "s|__BASE_IMAGE__|${BASE_IMAGE_NAMESPACE}-wildfly|g" "${DIR_CURRENT}/wildfly/Dockerfile" >"${DIR_BUILD}/wildfly/Dockerfile"
  download_and_copy_dwh_j2ee "/wildfly"
  copy_aktin_properties "/wildfly"
  download_and_copy_aktin_import_scripts "/wildfly/import-scripts"
  copy_wildfly_config "/wildfly"
}

prepare_postgresql_docker() {
  echo "Preparing PostgreSQL Docker image..."
  mkdir -p "${DIR_BUILD}/database"
  sed -e "s|__BASE_IMAGE__|${BASE_IMAGE_NAMESPACE}-database|g" "${DIR_CURRENT}/database/Dockerfile" >"${DIR_BUILD}/database/Dockerfile"
  copy_sql_scripts "/database/sql"
  copy_sql_update_scripts "/database/sql"
}

prepare_apache2_docker() {
  echo "Preparing Apache2 Docker image..."
  mkdir -p "${DIR_BUILD}/httpd"
  sed -e "s|__BASE_IMAGE__|${BASE_IMAGE_NAMESPACE}-httpd|g" "${DIR_CURRENT}/httpd/Dockerfile" >"${DIR_BUILD}/httpd/Dockerfile"
  copy_apache2_proxy_config "/httpd" "wildfly"
}

clean_up_old_docker_images() {
  echo "Cleaning up old Docker images and containers..."
  local images=("database" "wildfly" "httpd")
  for image in "${images[@]}"; do
    local full_image_name="${IMAGE_NAMESPACE}-${image}"

    # Stop and remove running containers based on the image
    local container_ids
    container_ids=$(docker ps -a -q --filter "ancestor=${full_image_name}:latest")
    if [ -n "${container_ids}" ]; then
      echo "Stopping and removing containers for image ${full_image_name}:latest"
      docker stop ${container_ids} || true
      docker rm ${container_ids} || true
    else
      echo "No containers found for image ${full_image_name}:latest"
    fi

    # Remove the Docker image
    if docker images "${full_image_name}:latest" -q >/dev/null; then
      echo "Removing image ${full_image_name}:latest"
      docker image rm "${full_image_name}:latest" || true
    else
      echo "Image ${full_image_name}:latest does not exist"
    fi
  done
}

build_docker_images() {
  echo "Building Docker images..."
  cwd="$(pwd)"
  cd "${DIR_CURRENT}"
  docker compose build
  cd "${cwd}"
}

main() {
  set -euo pipefail
  load_common_files_and_prepare_environment
  load_docker_environment_variables
  prepare_wildfly_docker
  prepare_postgresql_docker
  prepare_apache2_docker
  clean_up_old_docker_images
  build_docker_images
}

main
