#!/bin/bash

echo ">>> [Worker] Updating packages..."
sudo apt-get update -y
sudo apt-get install -y curl

# Définit l'URL du serveur K3s en utilisant l'IP fixe définie dans le Vagrantfile
export K3S_URL="https://192.168.56.110:6443"
echo ">>> [Worker] K3S Server URL set to: ${K3S_URL}"

# Chemin vers le fichier token dans le dossier partagé
TOKEN_FILE="/home/vagrant/scripts/k3s_token"

echo ">>> [Worker] Waiting for server token file..."
# Attendre que le fichier token existe (créé par le serveur)
while [ ! -f ${TOKEN_FILE} ]; do
  echo "Waiting for ${TOKEN_FILE} to be created by the server node..."
  sleep 5 # Attend 5 secondes avant de vérifier à nouveau
done

echo ">>> [Worker] Reading token..."
# Lire le token depuis le fichier
export K3S_TOKEN=$(cat ${TOKEN_FILE})

if [ -z "${K3S_TOKEN}" ]; then
  echo ">>> [Worker] ERROR: Failed to read K3S_TOKEN from ${TOKEN_FILE}"
  exit 1
fi

echo ">>> [Worker] Token read successfully. Installing k3s agent..."
# Exécute l'installation de l'agent K3s AVEC les variables K3S_URL et K3S_TOKEN
# Note: Pas besoin de sudo ici car le script get.k3s.io le gère lui-même
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server ${K3S_URL}" sh -

echo ">>> [Worker] Worker setup complete."
