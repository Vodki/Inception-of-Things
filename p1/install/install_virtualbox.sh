#!/bin/bash

# Arrêter le script en cas d'erreur
set -e

echo "--- Démarrage de l'installation de VirtualBox pour Ubuntu 24.04 ---"

# 1. Mise à jour du système et installation des dépendances de compilation
# VirtualBox a besoin de gcc, make et perl pour compiler ses modules noyau
echo "Mise à jour et installation des prérequis..."
sudo apt-get update -y
sudo apt-get install -y wget gpg apt-transport-https software-properties-common
sudo apt-get install -y build-essential dkms linux-headers-$(uname -r)

# 2. Ajout de la clé GPG officielle d'Oracle
echo "Ajout de la clé GPG Oracle..."
wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg

# 3. Ajout du dépôt officiel Oracle VirtualBox
echo "Ajout du dépôt Oracle..."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian noble contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list

# 4. Installation de VirtualBox 7.1
echo "Installation de VirtualBox 7.1..."
sudo apt-get update -y
sudo apt-get install -y virtualbox-7.1

# 5. Ajout de l'utilisateur actuel au groupe vboxusers
# Cela permet d'accéder aux périphériques USB sans être root
echo "Configuration des permissions utilisateur..."
sudo usermod -aG vboxusers $USER

# 6. Vérification
echo "--- Installation terminée ---"
vboxmanage --version

echo "IMPORTANT : Vous devez redémarrer votre session ou l'ordinateur pour que l'ajout au groupe 'vboxusers' soit pris en compte."