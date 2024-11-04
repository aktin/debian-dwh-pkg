#!/bin/bash
#--------------------------------------
# Script Name:  clean.sh
# Version:      1.1
# Authors:      skurka@ukaachen.de, akombeiz@ukaachen.de
# Date:         31 Oct 24
# Purpose:      Cleans up AKTIN DWH Debian package build directories.
#--------------------------------------

set -euo pipefail

dir_current="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf "${dir_current}/debian/build"
