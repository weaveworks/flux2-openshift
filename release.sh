#!/usr/bin/env bash
set -euo pipefail

version=${1:-master}
echo "Flux version: $version"

echo "Building the CLI image ..."
docker build -t flux-cli:v${version} \
  --build-arg FLUXCLI_VER=${version} \
  -f Dockerfile.fluxcli .

echo "Generating the manifests using the built CLI ..."
manifest="manifests-$version.yaml"
docker run --rm -it flux-cli:v${version} install --version="$version" \
  --components-extra=image-reflector-controller,image-automation-controller \
  --export --dry-run > "$manifest"

echo "Calling release js ..."
./release.js "$manifest" "$version"

echo "Bundle with operator-sdk ..."
operator-sdk bundle validate --select-optional name=operatorhub --verbose "flux/$version"

rm "$manifest"
