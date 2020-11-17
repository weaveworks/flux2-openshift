# Development

Below are steps to create a new operator version

```sh
NEW_VERSION=0.2.2 # update version
flux install --version=$NEW_VERSION --export --dry-run > manifests-${NEW_VERSION}.yaml
cp -r flux/0.2.2 flux/$NEW_VERSION
```

Manually copy individual manifests out of `manifests-${NEW_VERSION}.yaml` into respective files under the new directory.
The deployments have to be manually added to the `clusterserviceversion.yaml` under `spec.deployments`.
Bump up `flux.package.yaml`.

# Validate

```sh
cd flux/0.2.2
operator-sdk bundle validate --select-optional name=operatorhub --verbose .
```

# Test

Setting up OLM

```sh
kind create cluster
operator-sdk olm install
```

Rebuild Catalog

```sh
cp catalog.Dockerfile ../community-operators/
cd ../community-operators
docker build -f catalog.Dockerfile -t saada/olm-catalog:v1 .
docker push saada/olm-catalog:v1
```

Run test

```sh
kubectl delete catalogsource operatorhubio-catalog -n olm
kubectl apply -f test/
```

Test that Flux2 components are running and test CRDs.

# Submit

```sh
cp -r flux ../community-operators/upstream-community-operators/
```

Create a PR
