# https://pykickstart.readthedocs.io/en/latest/kickstart-docs.html
# Generated by pykickstart v3.52
#version=DEVEL

# Use graphical install
text --non-interactive
selinux --enforcing

# Firewall configuration
# BGP needed for Calico https://docs.tigera.io/calico/latest/getting-started/kubernetes/requirements
firewall --enable --service=ssh,bgp,kubelet,kube-control-plane-secure

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# System bootloader configuration
bootloader --location=mbr --driveorder=vda

# Partition clearing information
clearpart --drives=vda --all
zerombr
reqpart --add-boot
part / --fstype="xfs" --size=10 --grow

# Root password
rootpw --plaintext linux

# System timezone
timezone Europe/Rome --utc
timesource --ntp-pool europe.pool.ntp.org

# Reboot After Installation
shutdown --eject

# https://pagure.io/fedora-comps/blob/main/f/comps-f40.xml.in
%packages
@^server-product-environment
@guest-agents
%end

# User
user --name=maintainer --shell=/bin/sh --groups=wheel --gecos="Maintainer User"
sshkey --username=maintainer "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCcFl0R2o7EoDeJtZMub/iSUM3V0t0Mr425WmTDnMAF+f4Pz9Kx2NVYvDIY+1z7CgnziRO5sGqQhyTzBLuUoMX4IeWfOBQz51D+Wt9GUAufBW3GkIVKSUnzvFmOu13zcXH1rj1ACqn6A2aVCRbPMphTQrJf+IyeTxoNn23tX3mipMp+FGXSbzipbPI3Yjmv8SEcZyfnQb2OQmp1RXAayoAqSIQ7ghQ00QtgosUk2eVRz1MRVvzQ0v3xNvTeo54PnkbieR5qZOh2VmWvGhJpOkc9k3hLHUazkQ6vLO+fvQ5gXtJ1DWPOv8tbhg+9aHXtVK6k0JdciVLGeVIhFg0/+dLYsfQSGOiCdnZ7XYCv1nw3OIFJj5Kekk2raqSlHbffmEoua+x8dQNHpF2c0NdN8r3GZ5lvhWQApIpJ67OkAWDIqKvCE64WfxGdKr3wVNNQWbOWARzM2QOyGei3BuTbRJtFjRTniC9XVibPsIQgF8JuGSTHfpgNnDIOArYG2AsdL1+WLJ8fSSitHoRBuRMi97vVYhGWupsG806+CVagXsSb4K6ysnyiFJg43YqHbFFfYBMCPPLbL/xYIiWc4RGHBpCEcOvA4IO+O10XTijOTykbVUu2RIOr44yeXxjQ3YggC/iXmWPZqj4r9+CWoc4GhyAnLzsppiMeACr7sWyPtndUpQ=="


%post --log=post.log --erroronfail
#!/bin/sh

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
dnf install -y cri-o cri-tools crun crun-vm
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

# Install k8s packages and libvirt agent
dnf install -y kubernetes-kubeadm kubernetes-client
systemctl enable kubelet
systemctl enable qemu-guest-agent --now

# add admin user
echo "maintainer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
%end
