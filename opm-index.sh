#!/usr/bin/env bash
set -euo pipefail

#
# Prepare catalog for e2e testing
#

VERSION=$(cat LATEST_VERSION)

list=""
for i in $(ls -d flux/${VERSION}/ | xargs -I{} basename {}); do
  # docker build and push individual bundles
  docker build -t ghcr.io/weaveworks/openshift-fluxv2-catalog:bundle-v"${i}" -f bundle.Dockerfile flux/"${i}"
  docker push ghcr.io/weaveworks/openshift-fluxv2-catalog:bundle-v"${i}"
  list="$list,ghcr.io/weaveworks/openshift-fluxv2-catalog:bundle-v$i"
done

docker build -t opm -f Dockerfile.opm .

list=${list:1} # remove first comma
docker run --rm -it \
  --privileged \
  -v /var/lib/docker:/var/lib/docker \
  -v /var/run/docker.sock:/var/run/docker.sock \
  opm:latest index add \
  --container-tool docker \
  --bundles "$list" \
  --tag ghcr.io/weaveworks/openshift-fluxv2-index:latest

# push index
docker push ghcr.io/weaveworks/openshift-fluxv2-index:latest
