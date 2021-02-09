#!/usr/bin/env bash
set -euo pipefail

version=${1:-master}
echo "$version"

if ! which flux; then
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "os detected: linux"
    curl -s https://toolkit.fluxcd.io/install.sh | sudo bash
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "os detected: macOS"
    brew install fluxcd/tap/flux
  fi
fi

manifest="manifests-$version.yaml"
flux install --version="$version" --export --dry-run >"$manifest"
./release.js "$manifest" "$version"
operator-sdk bundle validate --select-optional name=operatorhub --verbose "flux/$version"
rm "$manifest"
