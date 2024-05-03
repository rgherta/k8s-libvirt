provider "libvirt" {
  uri = var.libvirt_uri
}

resource "libvirt_network" "subnet" {
  name      = "local-subnet-${var.node_type}"
  mode      = "route"
  addresses = [var.subnet_cidr]


  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled    = true
    local_only = true
  }

  dynamic routes {  
    for_each = var.routes
    content {
      cidr    = routes.value.cidr
      gateway = routes.value.gateway
    }
  }

}

resource "libvirt_pool" "cluster" {
  name = "cluster-${var.node_type}"
  type = "dir"
  path = "/tmp/cluster_storage"
}

resource "libvirt_volume" "root" {
  count = var.nbr_nodes
  name        = "root${count.index}-${var.node_type}"
  source      = "${path.module}/img/fedora40-${var.node_type}.qcow2"
  format      = "qcow2"
  pool        = libvirt_pool.cluster.name
  depends_on = [null_resource.build_image]
}

resource "libvirt_volume" "data" {
  count = var.nbr_nodes
  name  = "data${count.index}-${var.node_type}"
  size  = 10 * 1024 * 1024 * 1024 
  pool        = libvirt_pool.cluster.name
}

resource "libvirt_domain" "vm" {
  count = var.nbr_nodes

  name        = "vm-${var.node_type}-${count.index}"
  memory      = 4096
  vcpu        = 2
  qemu_agent = true

  network_interface {
    hostname = "vm-${var.node_type}-${count.index}"
    network_id     = libvirt_network.subnet.id
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.root[count.index].id
    scsi      = "true"
  }

  disk {
    volume_id = libvirt_volume.data[count.index].id
    scsi      = "true"
  }

}

