sudo dnf update -y

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -

sleep 10

kubectl apply -f /home/vagrant/apps/apps.yaml
kubectl apply -f /home/vagrant/apps/ingress.yaml