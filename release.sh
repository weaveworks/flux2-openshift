#!/usr/bin/env bash
set -euo pipefail

version=$(cat LATEST_VERSION)
echo "Flux version: $version"

echo "Generating the manifests using the built CLI ..."
manifest="manifests-$version.yaml"

echo "Exporting gotk-components.yaml ..."
docker run --rm -it ghcr.io/fluxcd/flux-cli:v${version} install --version="$version" \
  --components-extra=image-reflector-controller,image-automation-controller \
  --export > gotk-components.yaml

echo "Patch to remove fsGroup with Kustomize ..."
# require kustomize 4.1.3
kustomize build . > "$manifest"

QUERY=".spec.template.spec.containers[0].image"
source_controller_image=$(yq e "$QUERY | select(. == \"*source-controller*\")" gotk-components.yaml)

echo "Calling release js ..."
./release.js "${manifest}" "${version}" "${source_controller_image}"

echo "Bundle with operator-sdk ..."
operator-sdk bundle validate --select-optional name=operatorhub --verbose "flux/$version"

echo "Clean up ..."
# rm gotk-components.yaml
rm "$manifest"
