#!/usr/bin/env bash
# THIS IS MOSTLY FOR TESTING

set -euo pipefail
list=""
for i in $(ls -d flux/*/ | xargs basename); do
  # docker build and push individual bundles
  docker build -t saada/flux-catalog:bundle-v"${i}" -f bundle.Dockerfile flux/"${i}"
  docker push saada/flux-catalog:bundle-v"${i}"
  list="$list,registry-1.docker.io/saada/flux-catalog:bundle-v$i"

done
list=${list:1} # remove first comma
opm index add \
  --container-tool docker \
  --bundles "$list" \
  --tag saada/flux-index:latest
# push index
docker push saada/flux-index:latest
