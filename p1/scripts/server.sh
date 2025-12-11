#!/bin/bash

echo ">>> [Fix] Setting DNS to 8.8.8.8..."
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

echo ">>> [Server] Updating packages..."
sudo apt-get update -y
sudo apt-get install -y curl


echo ">>> [Server] Installing k3s server..."
# Installe k3s server. L'option --write-kubeconfig-mode est souvent utile.
# --node-ip ensures this node uses the host-only network IP (192.168.56.110)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode=644 --node-ip=192.168.56.110" sh -

echo ">>> [Server] Waiting for node token..."
# Attendre que le fichier token existe (peut prendre quelques secondes)
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  echo "Waiting for /var/lib/rancher/k3s/server/node-token to be created..."
  sleep 2
done

echo ">>> [Server] Copying node token to shared scripts directory..."
# Copie le token dans le dossier partagé pour que le worker puisse le lire
# /home/vagrant/scripts est le point de montage DANS la VM
# sudo cp /var/lib/rancher/k3s/server/node-token /home/vagrant/scripts/k3s_token

sudo cat /var/lib/rancher/k3s/server/node-token > /home/vagrant/scripts/k3s_token

sync

echo ">>> [Server] Server setup complete."
