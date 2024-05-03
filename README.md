# K8s with libvirt and fluxcd

Challenge: Create the needed Terraform and Kubernetes git repositories that allows you to tear up fully working kubernetes cluster with just editing a file and running 1-2 commands. The cluster should run Fluxcd to apply yaml files from a github repository ... [full task](https://github.com/c-wire/hiring-challenges/tree/main/devops-challenge)


## Describe approach

The infrastructure will be provisioned with terraform and libvirt provider. Main steps are outlined below.

Build OS Image from Base OS(Fedora|Ubuntu) with all needed packages, ansible ssh pubkey etc. Kickstart files can be used to customize Anaconda installation process.  We chose to use virt-builder with firstboot bash scripts for simplicity. One important thing to consider are [openscap](https://github.com/OpenSCAP) tools for security and compliance of such locally built images.

Provision 2 networks with different cidrs. Normally control and data plane should be placed in different physical networks. We try to simulate that and learn a bit more about libvirt networks. 

For post-provisioning choices we have cloud-init that comes from the Ubuntu world and Ignition that comes from CoreOS. We are using here ansible via ssh for simplicity and better control. Ansible playbook includes kubeadm commands for creating the control plane and joining worker nodes. Ansible like tools are a good choice of managing fleets of VMs.


## Install prerequisites

For this specific example, commands will be executed on Fedora40Workstation. Check opentofu manual installation guide in case of issues.

```
romh@fedora:~$ sudo dnf install -y git opentofu ansible-core
```

We need to install the virtualization package, mainly libvirt, libguestfs and other tools specific to each distribution. On Rocky8 the group is called "Virtualization Host".

```
romh@fedora:~$ sudo dnf group install -y --with-optional virtualization
romh@fedora:~$ echo "export XDG_RUNTIME_DIR=/run/user/$UID" >> ~/.bashrc
romh@fedora:~$ sudo usermod -a -G libvirt romh
romh@fedora:~$ sudo systemctl enable libvirtd --now

```

Notice we are logged in as a non-root user that belongs to sudo/wheel group but also libvirt group. Normally it is recommended to run libvirt commands as root to avoid permission issues. In the following opentofu scripts we will use the [session mode](https://libvirt.org/daemons.html). These changes were introduced since 2021 and include also a set of socket activated systemd services which makes debugging more difficult.

The machine is ready to provision libvirtd resources. 


## Provision resources

We will create control-plane with 1 VM and data-plane with 2 VMs. Make sure you review and/or edit **infra/main.tf** 

```
romh@fedora:~$ git clone https://github.com/rgherta/k8s-libvirt.git 
romh@fedora:~$ cd k8s-libvirt/infra/
romh@fedora:infra$ tofu init
romh@fedora:infra$ tofu apply
```

Notice libvirt created 2 networks in route mode with following cidrs:

* 10.32.0.0/28
* 10.16.0.0/28

Since the networks have [route mode](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_virtualization/configuring-virtual-machine-network-connections_configuring-and-managing-virtualization#virtual-networking-network-address-translation_types-of-virtual-machine-network-connections), the corresponding interfaces virbr<N> have been attached to the firwalld libvirt-routed zone. This zone contains nftable rules that allow communication between networks and with the underlying host as well.

The external interface should be attached to default zone, in fedora it is FedoraWorstation. You should be able to successfully test ping between machines and connectivity with host/internet.


## Run k8s

Terraform is great for provisioning resources, however when maintaining machines via ssh complexity increases using local-exec provisioners and local files.

Ansible is a good alternative for this and other use cases. In post_run.tf we generate the inventory.ini file that contains a list of all hosts and their ips. This file together with private ssh keys are copied onto ansible folder.

Kubernetes installation itself is done using ansible. To override the default make sure to edit **k8s.yml** or give as inline arguments like below

```
romh@fedora:infra$   cd ../ansible/
romh@fedora:ansible$ ansible-playbook playbooks/k8s.yml -e "podCIDR=192.168.32.0/24" -e "svcCIDR=172.16.32.0/24"

```

Some important considerations:

* Calico requires some additional linux kernel settings and ports opened. These are detailed in boot and ansible scripts. Networking plugins should also look for a special kubeadm configmap that is present in kubeadm provisioned clusters. This config map contains information about the 
* 


## Integrate FluxCD


## Conclusion

Libvirt is ok for a small development cluster as close as possible to bare metal.



resource "null_resource" "install_control_plane" {
  provisioner "local-exec" {
        command = "ssh -i /path/to/private_key.pem maintainer@[2001:0db8:85a3:0000:0000:8a2e:0370:7334]"
  }
  depends_on = [module.control-plane, module.data-plane]
}



{
  "control_plane": [
    "10.32.0.3"
  ],
  "data_plane": [
    "10.16.0.9",
    "10.16.0.2"
  ]
}


https://github.com/dmacvicar/terraform-provider-libvirt/issues/1024
https://github.com/dmacvicar/terraform-provider-libvirt/issues/978

https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_virtualization/configuring-virtual-machine-network-connections_configuring-and-managing-virtualization#virtual-networking-open-mode_types-of-virtual-machine-network-connections


https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/configuring_and_managing_virtualization/managing-storage-for-virtual-machines_configuring-and-managing-virtualization#assembly_managing-virtual-machine-storage-pools-using-the-cli_managing-storage-for-virtual-machines



https://libvirt.org/manpages/libvirtd.html

QEMU SESSION MODE