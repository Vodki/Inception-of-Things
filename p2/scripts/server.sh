echo ">>> [Fix] Setting DNS to 8.8.8.8..."
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

sudo apt-get update -y
sudo apt-get install -y curl

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -

sleep 10

kubectl apply -f /home/vagrant/apps/apps.yaml
kubectl apply -f /home/vagrant/apps/ingress.yaml