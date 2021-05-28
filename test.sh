make release
make opm-index

ekz create cluster

operator-sdk olm install

ls -d test/* | xargs -I{} kubectl apply -f {}
kubect get installplan -A
kubect get csv -A
kubectl get pods -n flux-system
watch kubectl get pods -n flux-system
