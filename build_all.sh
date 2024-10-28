#!/bin/bash
#--------------------------------------
# Script Name:  build_all.sh
# Version:      1.0
# Author:       skurka@ukaachen.de, akombeiz@ukaachen.de
# Date:         28 Oct 24
# Purpose:      Initiates AKTIN DWH component build processes for Debian packages and Docker images using the specified version.
#--------------------------------------

set -euo pipefail

# Check if VERSION is provided as the first argument
readonly VERSION="${1:-}"
if [[ -z "${VERSION}" ]]; then
  echo "Error: VERSION is not specified." >&2
  echo "Usage: $0 <version>"
  exit 1
fi

# Get the directory where this script is located
readonly DIR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

source "${DIR_ROOT}/debian/build.sh" "${VERSION}"
source "${DIR_ROOT}/docker/build.sh" "${VERSION}"
