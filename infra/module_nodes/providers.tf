terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.5"
    }
  }
}
