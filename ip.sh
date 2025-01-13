sudo rm -rf /etc/netplan/*
sudo touch /etc/netplan/10.yaml

read -p "IP: " ip;
read -p "/+MASK: " mask;
read -p "GATEWAY: " gateway;

sudo echo "
network:
  ethernets:
    enp0s3:
      addresses:
      - $ip$mask
      gateway4: $gateway
      nameservers:
        addresses:
        - 8.8.8.8
  version: 2
" > /etc/netplan/10.yaml

sudo netplan apply
