# K8s with libvirt and fluxcd

Challenge: Create the needed Terraform and Kubernetes git repositories that allows you to tear up fully working kubernetes cluster with just editing a file and running 1-2 commands. The cluster should run Fluxcd to apply yaml files from a github repository ... [full task](https://github.com/c-wire/hiring-challenges/tree/main/devops-challenge)

## Describe approach

The infrastructure will be provisioned with terraform and libvirt provider. OS Image with most of packages and firewall settings built locally from a base image of choice. Main steps are outlined below.

1. Build OS Image from Base OS(Fedora|Ubuntu) with all needed packages, ansible ssh pubkey etc  (builder.tf) . Nowadays there are different approaches - cloud-init that comes from the Ubuntu world and Kickstart files that come from RedHat family. We use virt-builder with bash scripts because it's somewhere in the middle of both worlds. From third party tools worth mentioning [Packer](https://developer.hashicorp.com/packer) and [ImageBuilder](osbuild.org)) is gaining grounds lately in the redhat world. One important thing to consider are [openscap](https://github.com/OpenSCAP) tools for security and compliance of such images as part of the build process or via ssh through periodic ansible scripts.

2. Provision 2 networks with different cidrs. Normally control and data plane should be placed in different physical networks. We try to simulate that and learn a bit more about libvirt networks. 

3. Provision machines and get their ips. For this reason, as a workaround we query directly libvirtd as terraform returns first lease which seems to be ipv6.

4. Administration using ansible via ssh. This includes kubeadm commands for creating the control plane and joining worker nodes. Ansible like tools are a good choice of managing fleets of VMs via ssh and also grouping them like in our case master and worker nodes.


## Install prerequisites

For this specific example, commands will be executed on fedora40. We need to install opentofu first, libguestfs for building local machine images, ansible-core for deploying k8s.

```
romh@fedora:~$ sudo dnf install -y opentofu libguestfs-tools ansible-core
```

We need to install the virtualization package and enable libvirtd. We will provision one kubernetes node on this machine using libvirtd that is a wrapper around qemu and kvm. For building the image we will use livemedia-creator from the lorax package.

```
romh@fedora:~$ sudo dnf group install -y --with-optional virtualization
romh@fedora:~$ sudo systemctl enable libvirtd --now
```

The machine is ready to provision libvirtd resources. It will provision 3 VMs with 2cpu and 2Gb ram each.

## Provision resources

We will create contorl plane with 1 VM and data plane with 2 VMs. Make sure you review and/or edit **infra/main.tf** 

```
romh@fedora:~$ git clone <MYURL> cd infra
romh@fedora:infra$ tofu init
romh@fedora:infra$ tofu apply
```

Notice libvirt created 2 networks in route mode with following cidrs:

* 10.32.0.0/28
* 10.16.0.0/28

Since the networks have [route mode](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_virtualization/configuring-virtual-machine-network-connections_configuring-and-managing-virtualization#virtual-networking-network-address-translation_types-of-virtual-machine-network-connections), the corresponding interfases virbr<N> have been attached to the firwalld libvirt-routed zone. This zone contains nftable rules that allow communication between networks and with the underlying host as well.

The host interface should be attached to FedoraWorkstation. If IPV6 is enable on host then you might encounter libvirt issues.


## Run k8s

Terraform is great for provisioning resources, however when maintaining machines via ssh complexity increases using local-exec provisioners and local files.

Ansible is a good alternative for this and other use cases. In post_run.tf we generate the inventory.ini file that contains a list of all hosts and their ips. This file together with private ssh keys are copied onto ansible folder.

Kubernetes installation itself is done using ansible. To override the default make sure to edit **k8s.yml** or give as arguments inline

```
romh@fedora:infra$   cd ../ansible/
romh@fedora:ansible$ ansible-playbook playbooks/k8s.yml -e "podCIDR=192.168.32.0/24" -e "svcCIDR=172.16.32.0/24"

```

Some important considerations:

* Calico requires some additional linux kernel settings and ports opened. These are detailed in boot and ansible scripts.
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


https://medium.com/@razichennouf/networking-and-troubleshooting-of-hypervisors-f0443d8a0e8
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_virtualization/configuring-virtual-machine-network-connections_configuring-and-managing-virtualization#virtual-networking-open-mode_types-of-virtual-machine-network-connections