terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}


variable "libvirt_uri" {
  default = "qemu:///system"
}

provider "libvirt" {
  uri = var.libvirt_uri
}

resource "libvirt_pool" "cluster" {
  name = "guest_images"
  type = "dir"
  target{
    path = "/guest_images"
  } 
}

module "control-plane" {
  source = "./module_nodes"
  subnet_cidr = "10.32.0.0/28"
  libvirt_uri = var.libvirt_uri
  nbr_nodes = 1
  node_type = "cp"

  #rebuild_images = false

  # routes = [{
  #   cidr = "0.0.0.0/0"
  #   gateway = "192.168.1.254"
  # }]

  depends_on = [ libvirt_pool.cluster ]
}

module "data-plane" {
  source = "./module_nodes"
  subnet_cidr = "10.16.0.0/28"
  libvirt_uri = var.libvirt_uri
  nbr_nodes = 1
  node_type = "dp"

  #rebuild_images = false
  depends_on = [ libvirt_pool.cluster ]
}

