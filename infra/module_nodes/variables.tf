variable "local_pool_path" {
  default = "/tmp"
}

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

