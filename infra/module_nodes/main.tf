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
  }

  dynamic routes {  
    for_each = var.routes
    content {
      cidr    = routes.value.cidr
      gateway = routes.value.gateway
    }
  }
}


resource "libvirt_volume" "root_base" {
  name        = "disk-${var.node_type}"
  pool        = "guest_images"
  source      = abspath("/guest_images/disk-image-${var.node_type}.qcow2")
  depends_on = [ null_resource.build_image ]

}

resource "libvirt_volume" "root" {
  count = var.nbr_nodes
  name                  = "root${count.index}-${var.node_type}"
  base_volume_id        = libvirt_volume.root_base.id
  base_volume_pool      = "guest_images"
  pool = "guest_images"
}

resource "libvirt_volume" "data" {
  count = var.nbr_nodes
  name  = "data${count.index}-${var.node_type}"
  size  = 10 * 1024 * 1024 * 1024 
  pool  = "guest_images"
}

resource "libvirt_domain" "vm" {
  count = var.nbr_nodes

  name        = "vm-${var.node_type}-${count.index}"
  memory      = 3072
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

