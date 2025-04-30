variable "subnet_cidr" {
  description = "Default libvirt network cidr"
  default = "10.32.0.0/17"
}

variable "nbr_nodes" {
  description = "Number of nodes to be provisioned"
  default = "2"
}

variable "libvirt_uri" {
  description = "Libvirt uri local or remote"
  default = "qemu:///system"
}

variable "node_type" {
  description = "Node type used for small configuration variations"
  default = "cp"
}

variable "routes" {
  description = "List of network routes"
  default = []
}

variable "rebuild_images" {
  default = true
}

variable "os_variant" {
  description = "virt-install --osinfo list"
  default = "fedora-unknown"
}

variable "os_url" {
  description = "Check differences at https://docs.fedoraproject.org/en-US/fedora/latest/fedora-downloads-info/"
  #default = "https://dl.fedoraproject.org/pub/fedora/linux/development/42/Server/x86_64/iso/Fedora-Server-dvd-x86_64-42-20250411.n.0.iso"
  default = "https://dl.fedoraproject.org/pub/fedora/linux/development/rawhide/Server/x86_64/iso/Fedora-Server-dvd-x86_64-Rawhide-20250429.n.0.iso"
}

variable "k8s_version" {
  description = "version to be deployed"
  default = "1.33"
}