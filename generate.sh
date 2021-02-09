#!/usr/bin/env bash
set -euo pipefail
for i in $(ls -d flux/*/ | xargs basename); do
  make release version="$i"
done
