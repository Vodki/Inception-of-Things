# P2 - Kubernetes Deployment with k3d (macOS)

This guide explains how to launch the P2 Kubernetes cluster using k3d on macOS, which is the recommended approach for Apple Silicon Macs.

## Prerequisites

1. **Docker Desktop**: Ensure Docker Desktop is installed and running on your Mac
   - Download from: https://www.docker.com/products/docker-desktop/

2. **k3d**: Install k3d using Homebrew
   ```bash
   brew install k3d
   ```

3. **kubectl**: Should be installed automatically with k3d, or install separately:
   ```bash
   brew install kubectl
   ```

## Launch Steps

### 1. Create the k3d Cluster

Create a new k3d cluster named `p2` with port mapping for ingress:

```bash
k3d cluster create p2 --servers 1 --port "8080:80@loadbalancer"
```

This command:
- Creates a single-node k3s cluster named `p2`
- Maps host port `8080` to container port `80` for the load balancer
- Automatically installs Traefik as the ingress controller

### 2. Verify Cluster is Running

Check that the cluster is up and accessible:

```bash
kubectl get nodes
```

You should see output like:
```
NAME              STATUS   ROLES                  AGE   VERSION
k3d-p2-server-0   Ready    control-plane,master   1m    v1.31.5+k3s1
```

### 3. Deploy Applications

Deploy the three sample applications:

```bash
kubectl apply -f apps/apps.yaml
kubectl apply -f apps/ingress.yaml
```

### 4. Verify Deployments

Check that all pods are running:

```bash
kubectl get pods -A
```

You should see:
- `app1`, `app2`, `app3` pods in the `default` namespace
- System pods in `kube-system` (Traefik, CoreDNS, etc.)

### 5. Test the Applications

Test the ingress routing using curl:

```bash
# Test app1
curl -H "Host: app1.com" http://localhost:8080/

# Test app2
curl -H "Host: app2.com" http://localhost:8080/

# Test app3
curl -H "Host: app3.com" http://localhost:8080/
```

Each should return an HTML page with the respective app's message.

### Optional: Browser Access

To access the apps in your browser, add these entries to `/etc/hosts`:

```bash
sudo sh -c 'echo "127.0.0.1 app1.com app2.com app3.com" >> /etc/hosts'
```

Then you can visit:
- http://app1.com:8080
- http://app2.com:8080
- http://app3.com:8080

## Cleanup

When you're done, delete the cluster:

```bash
k3d cluster delete p2
```

## Troubleshooting

### Port 80 Already in Use

If you get an error about port 80 being allocated, use a different port:

```bash
k3d cluster create p2 --servers 1 --port "8080:80@loadbalancer"
```

### Check Cluster Status

List all k3d clusters:
```bash
k3d cluster list
```

### View Cluster Logs

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik
```

### Reset Everything

If something goes wrong, delete and recreate:

```bash
k3d cluster delete p2
k3d cluster create p2 --servers 1 --port "8080:80@loadbalancer"
kubectl apply -f apps/apps.yaml
kubectl apply -f apps/ingress.yaml
```

## Notes

- The cluster runs in Docker containers, so Docker Desktop must be running
- All data is ephemeral - deleting the cluster removes everything
- The ingress controller (Traefik) is automatically installed by k3d
- Port 8080 on your host maps to port 80 in the cluster's load balancer

