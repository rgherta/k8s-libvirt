# K8s with libvirt 

## Describe approach

The infrastructure will be provisioned with terraform and libvirt provider. Main steps are outlined below.

1. Build OS Image from Base OS(Fedora|Ubuntu) with all needed packages.
2. Provision 2 networks with different cidrs.
3. For installing k8s and other tasks we use ansible.


## Install prerequisites

For this specific example, commands will be executed on Fedora40Workstation.

```
romh@fedora:~$ sudo dnf install -y git opentofu ansible-core
```

We need to install the virtualization package, mainly libvirt, libguestfs for image building and other tools specific to each distribution. On Rocky8 the group is called "Virtualization Host". Also make sure to create the storage pool based on disk availability. 

```
romh@fedora:~$ sudo dnf group install -y --with-optional virtualization
romh@fedora:~$ sudo usermod -a -G libvirt $USER 
romh@fedora:~$ sudo firewall-cmd --permanent --add-masquerade

ENABLE MASQUERADE ON HOST
```

Notice we are logged in as a non-root user that belongs to sudo/wheel group but also libvirt group. Some [changes](https://libvirt.org/daemons.html#switching-to-modular-daemons) were introduced around 2021 including support for libvirt modular daemons and this is the reason we do not enable libvirtd.service. Process qemu-system-x86_64 will run as qemu user as defined in qemu.conf . This is an unprivileged user but it needs access to node images we will build in terraform. This is the reason for the facl command. You may choose a different way.

The machine is ready to provision libvirtd resources. 


## Provision resources

We will create control-plane with 1 VM and data-plane with 2 VMs. Make sure you review and/or edit **infra/main.tf** before applying changes.

```
romh@fedora:~$ git clone https://github.com/rgherta/k8s-libvirt.git 
romh@fedora:~$ cd k8s-libvirt/infra/
romh@fedora:infra$ sudo tofu init
romh@fedora:infra$ sudo tofu apply
```

Notice libvirt created 2 networks in route mode with following cidrs:

* 10.32.0.0/28
* 10.16.0.0/28

The external interface should be attached to default zone, in fedora it is FedoraWorstation. You should be successful testing ipv4/6 connectivity also with host. To allow external route make sure to enable masquerade on host default zone as shown in the above step.


## Run k8s

Terraform is great for provisioning resources, however when maintaining machines via ssh complexity increases using local-exec provisioners and local files.

Ansible is a good alternative for this and other use cases. In post_run.tf we generate the inventory.ini file that contains a list of all hosts and their ips. This file together with private ssh keys are copied onto ansible folder.

Kubernetes installation itself is done using ansible. To override the default make sure to edit **k8s.yml** or give as inline arguments like below, Make sure ssh keys have the correct owner.

```
romh@fedora:infra$   cd ../ansible/
romh@fedora:ansible$ ansible-playbook playbooks/k8s.yml -e "podCIDR=192.168.32.0/24" -e "svcCIDR=172.16.32.0/24"
```

At this point we have the cluster running and kubernetes configured with main important deployments.


## Considerations

Some of the main learning points are outlined below.

* Image building can be done with Kickstart files as part of anaconda installation process or Ignition/Cloudinit files. An important step when building such images locally is to scan them with openscap tools. This is what we are doing in ansible scripts. During builder.tf we also copy the public keys to be used by ansible and a default root password is set for debugging purposes.

* Libvirt can run in both system and [session mode](https://libvirt.org/daemons.html). While session mode is less privileged and preferred for small setups, it will not be able to provision multiple networks without additional manual setup. Most platforms use libvirt in *system mode* because it needs networks, host devices and interfaces, mounting and sharing filesystems etc. This is the reason tofu commands are ran as sudo.

* Libvirt networks.... firewalld zones etc...
Since the networks have [route mode](https://libvirt.org/firewall.html), the corresponding interfaces virbr<N> have been attached to the firewalld libvirt-routed zone. This zone contains nftable rules that allow communication between networks and with the underlying host as well.

* Calico requires some additional linux kernel settings and bgp ports open. These are detailed in boot and ansible scripts. Normally networking plugins should  look for a special kubeadm configmap that is present in kubeadm provisioned clusters. This config map contains information about the requested cidr without the need to additionally enter it in the networking plugin configuration. This is not the case for calico it seems.

* Lvm is used to create a volume group on all the nodes and this will be our default k8s storage class in order to avoid using hostpath and all the permission issues this will bring.

* Ansible scans the nodes and saves openscap reports in the ./scans folder. It is a practice used more often in platforms managing images. Reports contain a list of issues and manual fixes. There is a possibility to automate the process, refer to the relevant documentation.



## Conclusion

Libvirt is ok for a small development cluster as close as possible to bare metal.


firewall-cmd --list-services !!!
always use ksflatten