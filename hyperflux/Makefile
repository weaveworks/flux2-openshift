IMG ?= ghcr.io/weaveworks/flux2-openshift/hyperflux
TAG ?= v0.24.0

docker-build:
	./build-and-push.sh ${IMG} ${TAG}

scan: docker-push
	grype ${IMG}:${TAG}
