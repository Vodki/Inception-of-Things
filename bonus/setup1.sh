#!/bin/bash

# ============================================
# Setup script for Bonus - GitLab local
# ============================================

if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root (utilisez sudo)." 
   exit 1
fi


# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================
# 1. Vérifier les prérequis
# ============================================

if ! command -v helm &> /dev/null; then
    log_error "Helm n'est pas installé. Installation..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

log_success "Prérequis OK"

# ============================================
# 2. Créer le namespace gitlab
# ============================================
log_info "Création du namespace gitlab..."
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -
log_success "Namespace gitlab créé"

# ============================================
# 3. Ajouter le repo Helm GitLab
# ============================================
log_info "Ajout du repo Helm GitLab..."
helm repo add gitlab https://charts.gitlab.io/
helm repo update
log_success "Repo Helm GitLab ajouté"

# ============================================
# 4. Installer GitLab via Helm
# ============================================
log_info "Installation de GitLab (cela peut prendre plusieurs minutes)..."



helm upgrade --install gitlab gitlab/gitlab \
    --namespace gitlab \
    --values "./gitlab-values.yaml" \
    --timeout 10m \
    --wait

log_success "GitLab installé"

# ============================================
# 5. Attendre que GitLab soit prêt
# ============================================
log_info "Attente du démarrage de GitLab..."
kubectl wait --for=condition=available deployment/gitlab-webservice-default \
    --namespace gitlab \
    --timeout=600s || log_warning "Timeout atteint, GitLab peut encore démarrer..."

# ============================================
# 6. Afficher les informations de connexion
# ============================================
log_info "============================================"
log_info "GitLab est installé !"
log_info "============================================"
log_info ""
log_info "URL: http://gitlab.localhost:8080"
log_info ""
log_info "Username: root"
log_info "Password:"
log_info "$(kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d)"
log_info ""
log_info "============================================"
log_info "Prochaines étapes:"
log_info "1. Connectez-vous à GitLab"
log_info "2. Créez un projet nommé 'playground-app'"
log_info "3. Changez l'email dans bonus/setup2.sh avant de l'exécuter"
log_info "4. Lancez bonus/setup2.sh"
log_info "============================================"
