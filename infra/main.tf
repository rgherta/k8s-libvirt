terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
}

variable "libvirt_uri" {
  default = "qemu:///session"
}

module "control-plane" {
  source = "./module_nodes"
  subnet_cidr = "10.32.0.0/28"
  pool = "guest_images_dir"
  libvirt_uri = var.libvirt_uri
  node_type = "cp"
  nbr_nodes = 1

  #rebuild_images = false
}

module "data-plane" {
  source = "./module_nodes"
  subnet_cidr = "10.16.0.0/28"
  pool = "guest_images_dir"
  libvirt_uri = var.libvirt_uri

  nbr_nodes = 1
  node_type = "dp"
  #rebuild_images = false
}

