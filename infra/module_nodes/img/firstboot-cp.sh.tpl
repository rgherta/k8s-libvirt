#!/bin/sh

timedatectl set-timezone Europe/Rome

# Kernel modules
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

systemctl restart systemd-modules-load.service

# Kernel params
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
user.max_pid_namespaces             = 1048576
user.max_user_namespaces            = 1048576
EOF

# Calico requirements https://docs.tigera.io/calico/latest/operations/troubleshoot/troubleshooting#:~:text=Error%3A%20calico%2Fnode%20is%20not,is%20allowed%20in%20the%20environment.
cat <<EOF | tee /etc/sysctl.d/calico.conf
net.netfilter.nf_conntrack_max=1000000
EOF

sysctl --system

# Install runtime
rm -rf /etc/cni/net.d/*  

sed -i 's/# cgroup_manager/cgroup_manager/g' /etc/crio/crio.conf
sed -i 's/# default_runtime = "runc"/default_runtime = "crun"/g' /etc/crio/crio.conf
mkdir /etc/crio/crio.conf.d

# Crun a memory efficient container runtime
tee -a /etc/crio/crio.conf.d/90-crun <<CRUN 
[crio.runtime.runtimes.crun]
runtime_path = "/usr/bin/crun"
runtime_type = "oci"
CRUN

# settings for usernamespace containers - main openshift security advantage
echo "containers:1000000:1048576" | tee -a /etc/subuid
echo "containers:1000000:1048576" | tee -a /etc/subgid

tee -a /etc/crio/crio.conf.d/91-userns <<USERNS 
[crio.runtime.workloads.userns]
activation_annotation = "io.kubernetes.cri-o.userns-mode"
allowed_annotations = ["io.kubernetes.cri-o.userns-mode"]
USERNS

# Crun-rm a virtualized container runtime for untrusted workload
tee -a /etc/crio/crio.conf.d/92-crunvm <<CRUNVM 
[crio.runtime.runtimes.crun-vm]
runtime_path = "/usr/local/bin/crun-vm"
CRUNVM

chcon -R --reference=/etc/crio/crio.conf  /etc/crio/crio.conf.d/ 

systemctl daemon-reload
systemctl enable crio --now 

# Handle swap
swapoff -a
zramctl --reset /dev/zram0
dnf -y remove zram-generator-defaults

# Install k8s packages
systemctl enable kubelet
systemctl enable qemu-guest-agent

# Firewall rules CP
systemctl enable firewalld --now
firewall-cmd --set-default-zone=internal
firewall-cmd --permanent --add-port=6443/tcp --add-port=2379-2380/tcp --add-port=10250/tcp --add-port=10259/tcp --add-port=10257/tcp
firewall-cmd --reload

# Calico https://docs.tigera.io/calico/latest/getting-started/kubernetes/requirements
firewall-cmd --permanent --add-port=179/tcp 
firewall-cmd --reload

# add admin user
useradd maintainer --create-home --groups wheel --shell /bin/bash --comment "cwire maintainer user"
mkdir /home/maintainer/.ssh/
echo "${maintainer_public_key}" > /home/maintainer/.ssh/authorized_keys
chmod 600 /home/maintainer/.ssh/authorized_keys
chown -R maintainer:maintainer /home/maintainer/.ssh
echo "maintainer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


