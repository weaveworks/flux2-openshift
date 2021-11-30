IMG=$1
TAG=$2

QUERY=".spec.template.spec.containers[0].image"

SOURCE_IMG=$(yq e "$QUERY | select(. == \"*source-controller*\")" ../gotk-components.yaml)
KUSTOMIZE_IMG=$(yq e "$QUERY | select(. == \"*kustomize-controller*\")" ../gotk-components.yaml)
HELM_IMG=$(yq e "$QUERY | select(. == \"*helm-controller*\")" ../gotk-components.yaml)
NOTIFICATION_IMG=$(yq e "$QUERY | select(. == \"*notification-controller*\")" ../gotk-components.yaml)
IMAGE_AUTOMATION_IMG=$(yq e "$QUERY | select(. == \"*image-automation-controller*\")" ../gotk-components.yaml)
IMAGE_REFLECTOR_IMG=$(yq e "$QUERY | select(. == \"*image-reflector-controller*\")" ../gotk-components.yaml)

docker buildx build \
	-f Dockerfile \
	--no-cache \
	--build-arg SOURCE_IMG=$SOURCE_IMG \
	--build-arg KUSTOMIZE_IMG=$KUSTOMIZE_IMG \
	--build-arg HELM_IMG=$HELM_IMG \
	--build-arg NOTIFICATION_IMG=$NOTIFICATION_IMG \
	--build-arg IMAGE_AUTOMATION_IMG=$IMAGE_AUTOMATION_IMG \
	--build-arg IMAGE_REFLECTOR_IMG=$IMAGE_REFLECTOR_IMG \
	--platform="linux/amd64,linux/arm64" \
	-t ${IMG}:${TAG} \
	--push .
