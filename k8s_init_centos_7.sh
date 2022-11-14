#!/bin/sh

yum update -y
systemctl disable --now firewalld
setenforce 0
systemctl disable --now NetworkManager
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF


modprobe overlay
modprobe br_netfilter
tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF


sysctl --system
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum update -y && yum install -y containerd.io

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

systemctl restart containerd
systemctl enable --now containerd


cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
