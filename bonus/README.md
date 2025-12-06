# Bonus - GitLab Local avec ArgoCD

Ce bonus remplace GitHub par une instance GitLab locale qui fonctionne avec ArgoCD.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Cluster k3d                              │
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   GitLab    │───▶│   ArgoCD    │───▶│  App (dev)  │     │
│  │  (gitlab)   │    │  (argocd)   │    │             │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│        │                  │                  │              │
│        ▼                  ▼                  ▼              │
│   gitlab.localhost  argocd.localhost  playground.localhost │
│       :8080              :8080              :8080           │
└─────────────────────────────────────────────────────────────┘
```

## Prérequis

- Cluster k3d fonctionnel (avec p3 complétée)
- Helm installé
- ~6-8 GB de RAM disponible

## Installation

### 1. Lancer le script de setup

```bash
cd bonus
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 2. Attendre que GitLab démarre

GitLab prend plusieurs minutes à démarrer. Vérifiez l'état :

```bash
kubectl get pods -n gitlab
```

Tous les pods doivent être en état `Running` ou `Completed`.

### 3. Récupérer le mot de passe root GitLab

```bash
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

### 4. Accéder à GitLab

Ouvrez http://gitlab.localhost:8080

- **Username**: `root`
- **Password**: (celui récupéré à l'étape 3)

### 5. Créer un projet dans GitLab

1. Cliquez sur "New project"
2. Choisissez "Create blank project"
3. Nom: `playground-app`
4. Visibilite: Public
5. Décochez "Initialize repository with a README"
6. Cliquez "Create project"

### 6. Pusher les manifests vers GitLab

```bash
# Cloner le projet vide

git clone http://gitlab.localhost:8080/root/playground-app.git


# Copier les manifests
cp ./p3/app/ ./playground-app/

# Commit et push
git add .
git commit -m "Initial app manifests"
git push origin main
```

### 8. Appliquer l'Application ArgoCD

```bash
kubectl apply -f confs/application.yaml
```

### 9. Vérifier

- ArgoCD UI: http://argocd.localhost:8080
- L'application doit être "Synced" et "Healthy"
- App accessible: http://playground.localhost:8080

## Test de synchronisation

1. Modifiez un fichier dans GitLab (ex: changer `replicas: 2`)
2. ArgoCD détecte le changement automatiquement
3. Vérifiez : `kubectl get pods -n dev`

## Troubleshooting

### GitLab ne démarre pas

```bash
# Voir les logs
kubectl logs -n gitlab -l app=webservice --tail=50

# Vérifier les events
kubectl get events -n gitlab --sort-by=.lastTimestamp
```

### ArgoCD ne peut pas accéder à GitLab

1. Vérifier que le repo est public ou que le secret est configuré
2. Tester la connectivité :

```bash
kubectl run curl-test --rm -it --image=curlimages/curl -n argocd -- \
  curl -s http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/playground-app.git
```

### Ressources insuffisantes

GitLab nécessite beaucoup de RAM. Si les pods crashent (OOMKilled) :

```bash
# Vérifier les ressources
kubectl top pods -n gitlab

# Augmenter les limites dans gitlab-values.yaml
```

## Nettoyage

```bash
# Supprimer GitLab
helm uninstall gitlab -n gitlab
kubectl delete namespace gitlab

# Remettre l'application p3 (GitHub)
kubectl apply -f ../p3/application.yaml
```

## Fichiers

```
bonus/
├── README.md                           # Ce fichier
├── scripts/
│   └── setup.sh                        # Script d'installation
├── gitlab-values.yaml              # Configuration Helm GitLab
├── gitlab-ingress.yaml             # Ingress backup
└──  application.yaml                # ArgoCD Application (GitLab)
```
