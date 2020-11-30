#!/usr/bin/env bash
set -euo pipefail
list=""
for i in $(ls -d flux/*/ | xargs basename); do
  make version="$i"
  list="$list,registry-1.docker.io/saada/flux-catalog:bundle-v$i"
done
list=${list:1} # remove first comma
opm index add \
  --container-tool docker \
  --bundles "$list" \
  --tag saada/flux-index:latest
docker push saada/flux-index:latest
