# Flux2 Openshift

## Prerequisites

- opm 1.5.2
- operator-sdk
- docker (optional)

## Make a release

```sh
npm install # you need nodejs installed
make release version=<VERSION>
make release version=0.2.3
# release and publish all versions. To add new version, simply add a new flux/<version> directory with the desired version and let the script generate everything
# example: mkdir flux/0.5.{0..9} flux/0.6.{0..3} flux/0.7.{0..7}
make generate
```

Submit to Operator Hub

```sh
cd ../community-operators # make sure it's a clone of your own fork of https://github.com/operator-framework/community-operators
git checkout master
git pull
git checkout -b flux-releases-0.7.7
cp -r ../openshift-flux2/flux ./upstream-community-operators/
git add upstream-community-operators/flux
git commit -m 'release flux versions 0.4.3-0.7.7'
git commit --amend --no-edit --signoff
git push -u fork flux-releases-0.7.7
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

## Test using RedHat's test suite

Make sure you have Docker running.
If you have a Mac, make sure you have GNU `sed` in your path working

```sh
bash <(curl -sL https://cutt.ly/WhkV76k) \
all \ # you can also set this to kiwi test suite
upstream-community-operators/flux/0.8.2 \ # file path
https://github.com/saada/community-operators flux-releases-0.7.7 # branch name
```

## Test with CRC or KIND

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
