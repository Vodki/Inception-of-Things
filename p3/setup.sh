#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root (utilisez sudo)." 
   exit 1
fi
curl -sfL https://get.k3s.io | sh -
k3d cluster create IoT -p "8080:80@loadbalancer" -p "8443:443@loadbalancer"
kubectl create namespace argocd
kubectl create namespace dev
kubectl apply -n argocd -f ingress.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attendre que le pod argocd-server soit prêt
echo "Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=120s

# Configurer ArgoCD en mode HTTP (insecure)
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout status deployment argocd-server -n argocd

kubectl apply -n argocd -f application.yaml

echo ""
echo "============================================"
echo "ArgoCD is ready!"
echo "URL: http://argocd.localhost"
echo "Username: admin"
echo -n "Password: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo "============================================"