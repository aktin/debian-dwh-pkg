#!/bin/bash
set -euo pipefail
. debian/build.sh "$1"
. docker/build.sh "$1" "full"
