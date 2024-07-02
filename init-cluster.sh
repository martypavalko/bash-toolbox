#!/bin/bash

IP="ip a | grep ens192 | grep inet | awk '{print $2}' | sed 's/\/[0-9]*//g'"
mkdir -p /opt/kubernetes
# TODO: Add validation for containerd existing on the node, and the configuration existing at path
grep Systemd /etc/containerd/config.toml | sudo sed -i 's/false/true/g' /etc/containerd/config.toml
# TODO: Add validation to see if these files already exist and if they contain the same information
tee /opt/kubernetes/cluster.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
clusterName: "staging"
controlPlaneEndpoint: $IP:6443
networking:
    podSubnet: "10.244.0.0/16"
EOF
tee -a /opt/kubernetes/calico.yaml <<EOF
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - name: default-ipv4-ippool
      blockSize: 26
      cidr: 10.244.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF
# kubeadm init --pod-cidr-network=10.244.0.0/16 --control-plane-endpoint="$IP"
kubeadm init --config=/opt/kubernetes/cluster.yaml
# TODO: Create better automation for calico install
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
kubectl apply -f /opt/kubernetes/calico.yaml
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install helm
# mkdir -p "$HOME/.kube/"
# cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config" 
# chown "$(id -u)":"$(id -g)" "$HOME/.kube"
