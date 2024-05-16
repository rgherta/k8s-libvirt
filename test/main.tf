
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


provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "root" {
  name  = "root"
  size  = 50 * 1024 * 1024 * 1024 # 50 GB
  pool  = "default"
}

resource "libvirt_domain" "vm" {
  #qemu_agent = true
  name        = "my_test_vm"
  memory      = 4096
  vcpu        = 2

  network_interface {
    network_name   = "default"
    #wait_for_lease = true
  }

  disk {
    file = "/home/romh/Documents/k8s-libvirt/test/fedora40-server.iso"
  }

  disk {
    file = "/home/romh/Documents/k8s-libvirt/test/fedora40-server.iso"
  }

  disk {
    volume_id = libvirt_volume.root.id
    scsi      = "true"
  }

  boot_device {
    dev = [ "hd", "cdrom"]
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

}

