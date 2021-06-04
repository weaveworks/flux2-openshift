# make release
# make opm-index

ekz create cluster

operator-sdk olm install

ls -d test/* | xargs -I{} kubectl apply -f {}

INSTALL_PLAN=$(kubectl get installplan -n flux-system -oyaml | yq e .items[].metadata.name -)

kubectl wait --for=condition=Installed=true installplan/$INSTALL_PLAN -n flux-system 

kubectl get installplan -A
kubectl get csv -A
kubectl get pods -n flux-system
