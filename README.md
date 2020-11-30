# Flux2 Openshift

## Prerequisites

- opm 1.5.2
- operator-sdk
- do

## Make a release

```sh
npm install # you need nodejs installed
make version=<VERSION>
make version=0.2.3
# release and publish all versions. To add new version, simply add a new flux/<version> directory with the desired version and let the script generate everything
make all
```

Submit to Operator Hub

```sh
cp -r flux ../community-operators/upstream-community-operators/
```

Create PR against [community-operators](https://github.com/operator-framework/community-operators)

## How it works

Below are steps to create a new operator version

```sh
NEW_VERSION=0.2.2 # update version
flux install --version=$NEW_VERSION --export --dry-run > manifests-${NEW_VERSION}.yaml
cp -r flux/0.2.2 flux/$NEW_VERSION
```

Manually copy individual manifests out of `manifests-${NEW_VERSION}.yaml` into respective files under the new directory.
The deployments have to be manually added to the `clusterserviceversion.yaml` under `spec.deployments`.

We then validate the release

```sh
cd flux/0.2.2
operator-sdk bundle validate --select-optional name=operatorhub --verbose .
```

## Test

Set up either kind or crc cluster

```sh
# A) KIND CLUSTER
kind create cluster
operator-sdk olm install
# B) CRC CLUSTER
crc setup
crc start --nameserver=1.1.1.1
```

Rebuild Catalog

```sh
docker build -t saada/olm-catalog:v3 .
docker push saada/olm-catalog:v3
```

Run test

```sh
kubectl delete catalogsource operatorhubio-catalog -n olm
kubectl apply -f test/catalog-source.yaml
kubectl apply -f test/operator-subscription.yaml
```

Test that Flux2 components are running and test CRDs.
