#!/bin/bash

# ============================================
# Setup script for Bonus - GitLab local
# ============================================

if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root (utilisez sudo)." 
   exit 1
fi

rm -rf /tmp/playground-app
git clone git@gitlab.localhost:8080/root/playground-app.git /tmp/playground-app
cp -r ./app/* /tmp/playground-app/

cd /tmp/playground-app

# Email generé par GitLab (a changer avant de lancer le script)
git config --local user.email "gitlab_admin_92fcf0@example.com"
git config --local user.name "Administrator"

git add .
git commit -m "Add Kubernetes deployment manifests"
git push origin main

cd -
kubectl apply -f application.yaml -n argocd