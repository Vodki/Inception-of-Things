#!/bin/bash

# Arrêter le script en cas d'erreur
set -e

echo "--- Démarrage de l'installation de VirtualBox pour Ubuntu 24.04 ---"

# 0. Vérifier la présence de modules KVM et les désactiver si nécessaire
echo "Vérification des modules KVM (kvm, kvm_intel, kvm_amd)..."
KVM_MODULES=(kvm_intel kvm_amd kvm)
KVM_PRESENT=false
for m in "${KVM_MODULES[@]}"; do
	if lsmod | grep -q "^$m"; then
		KVM_PRESENT=true
	fi
done

if [ "$KVM_PRESENT" = true ]; then
	echo "Modules KVM détectés. Tentative de désactivation pour permettre l'utilisation de VirtualBox..."
	sudo systemctl stop libvirtd.service 2>/dev/null || true
	sudo systemctl disable --now libvirtd.service 2>/dev/null || true
	sudo modprobe -r kvm_intel kvm_amd kvm 2>/dev/null || true
	echo -e "blacklist kvm\nblacklist kvm_intel\nblacklist kvm_amd" | sudo tee /etc/modprobe.d/blacklist-kvm.conf >/dev/null
	if command -v update-initramfs >/dev/null 2>&1; then
		sudo update-initramfs -u -k all >/dev/null 2>&1 || true
	fi
	echo "KVM modules unloaded and blacklisted. A reboot is recommended for changes to take effect."
fi

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