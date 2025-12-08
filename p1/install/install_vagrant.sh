#!/bin/bash

# Arrêter le script en cas d'erreur
set -e

echo "--- Démarrage de l'installation de Vagrant pour Ubuntu 24.04 ---"

# 1. Mise à jour des paquets existants
echo "Mise à jour du système..."
sudo apt-get update -y

# 2. Installation des prérequis nécessaires
echo "Installation des dépendances (wget, gpg)..."
sudo apt-get install -y wget gpg coreutils

# 3. Ajout de la clé GPG officielle de HashiCorp
echo "Ajout de la clé GPG HashiCorp..."
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg --yes

# 4. Ajout du dépôt officiel aux sources
echo "Ajout du dépôt HashiCorp..."
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# 5. Mise à jour des sources et installation de Vagrant
echo "Installation de Vagrant..."
sudo apt-get update -y
sudo apt-get install -y vagrant

# 6. Vérification de l'installation
echo "--- Installation terminée ---"
vagrant --version

echo "Note : N'oubliez pas d'installer un hyperviseur (comme VirtualBox ou KVM) pour utiliser Vagrant."