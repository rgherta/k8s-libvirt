terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
}

# make sure you have enough space
variable "local_pool_path" {
  default = "/home/romh/"
}

variable "libvirt_uri" {
  default = "qemu:///session"
}

module "control-plane" {
  source = "./module_nodes"
  subnet_cidr = "10.32.0.0/28"
  nbr_nodes = 1
  libvirt_uri = var.libvirt_uri
  node_type = "cp"

  #rebuild_images = false
}

module "data-plane" {
  source = "./module_nodes"
  subnet_cidr = "10.16.0.0/28"
  nbr_nodes = 1
  libvirt_uri = var.libvirt_uri
  node_type = "dp"

  #rebuild_images = false
}

