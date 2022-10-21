# make release
# make opm-index

kind create cluster

#force use olm 0.21.2 until 0.22 is verified with Flux
operator-sdk olm install --version 0.21.2

# To use latest olm release, remove --version 0.21.2 from line 8
# operator-sdk olm install

ls -d test/* | xargs -I{} kubectl apply -f {}


sleep 60


INSTALL_PLAN=$(kubectl get installplan -n flux-system -oyaml | yq e .items[].metadata.name -)

kubectl wait --for=condition=Installed=true installplan/$INSTALL_PLAN -n flux-system 

kubectl get installplan -A
kubectl get csv -A

# kubectl wait --for=condition=phase=Succeeded csv/flux.v0.15.3 -n flux-system

sleep 60

kubectl wait --for=condition=Ready=true pod -lapp=source-controller -n flux-system
kubectl wait --for=condition=Ready=true pod -lapp=kustomize-controller -n flux-system
kubectl wait --for=condition=Ready=true pod -lapp=helm-controller -n flux-system
kubectl wait --for=condition=Ready=true pod -lapp=notification-controller -n flux-system
kubectl wait --for=condition=Ready=true pod -lapp=image-automation-controller -n flux-system
kubectl wait --for=condition=Ready=true pod -lapp=image-reflector-controller -n flux-system

kubectl get pods -n flux-system
