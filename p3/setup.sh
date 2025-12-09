#!/bin/bash

k3d cluster create IoT -p "8080:80@loadbalancer" -p "8443:443@loadbalancer"
kubectl create namespace argocd
kubectl create namespace dev
kubens argocd
kubectl apply -n argocd -f ingress.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -n argocd -f application.yaml