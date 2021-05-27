#!/usr/bin/env bash
set -euo pipefail
make release version=$(cat LATEST_VERSION)
