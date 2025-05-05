#!/bin/bash

echo ">>> [Server] Updating packages..."
sudo dnf update -y

echo ">>> [Server] Installing k3s server..."
# Installe k3s server. L'option --write-kubeconfig-mode est souvent utile.
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode=644" sh -

echo ">>> [Server] Waiting for node token..."
# Attendre que le fichier token existe (peut prendre quelques secondes)
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  echo "Waiting for /var/lib/rancher/k3s/server/node-token to be created..."
  sleep 2
done

echo ">>> [Server] Copying node token to shared scripts directory..."
# Copie le token dans le dossier partagé pour que le worker puisse le lire
# /home/vagrant/scripts est le point de montage DANS la VM
sudo cp /var/lib/rancher/k3s/server/node-token /home/vagrant/scripts/k3s_token

echo ">>> [Server] Server setup complete."
