#!/bin/bash
#--------------------------------------
# Script Name:  build.sh
# Version:      1.1
# Authors:      skurka@ukaachen.de, akombeiz@ukaachen.de
# Date:         31 Oct 24
# Purpose:      Builds AKTIN DWH Debian package components for the specified version.
#--------------------------------------

set -euo pipefail

# Verify if a version is specified as an argument
readonly VERSION="${1:-}"
if [[ -z "${VERSION}" ]]; then
  echo "Error: VERSION is not specified." >&2
  echo "Usage: $0 <version>"
  exit 1
fi

# Define the root directory of the script
readonly DIR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

source "${DIR_ROOT}/debian/build.sh" "${VERSION}"
