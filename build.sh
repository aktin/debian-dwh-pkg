#!/bin/bash
set -euo pipefail
. debian/build.sh "$1" "$2"
. docker/build.sh "$1" "$2" "full"
