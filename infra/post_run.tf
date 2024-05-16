resource "null_resource" "get_ipv4" {
  triggers = { always_run = "${timestamp()}" }

  provisioner "local-exec" {
        command = <<-EOT
            sleep 5s
            libvirt_uri=${var.libvirt_uri}
            arg1=$(virsh --connect $libvirt_uri net-dhcp-leases local-subnet-cp | awk '{print $5 }' | tr '\n' ' ' |  grep -Eo '[0-9\.]+{7,12}' | jq -R . | jq -s)
            arg2=$(virsh --connect $libvirt_uri net-dhcp-leases local-subnet-dp | awk '{print $5 }' | tr '\n' ' ' |  grep -Eo '[0-9\.]+{7,12}' | jq -R . | jq -s)
            echo "{\"control_plane\": $arg1, \"data_plane\": $arg2}" | jq > ips.json
        EOT

        interpreter = ["/bin/sh", "-c"]
  }

  depends_on = [module.control-plane, module.data-plane]
}

data "local_file" "ips" {
  filename = "ips.json"
  depends_on = [null_resource.get_ipv4]
}

resource "local_file" "ansible_inventory" {
  filename = "inventory.ini"
  content = templatefile("ansible_inventory.tpl", { ips = jsondecode(data.local_file.ips.content) })

  depends_on = [null_resource.get_ipv4]
}


resource "null_resource" "copy_ansible_files" {
  triggers = { always_run = "${timestamp()}" }

  provisioner "local-exec" {
        command = <<-EOT
            cp -f module_nodes/keys/* ../ansible/keys/
            cp -f inventory.ini ../ansible/
            chmod 600 ../ansible/keys/* 
        EOT

        interpreter = ["/bin/sh", "-c"]
  }

  depends_on = [local_file.ansible_inventory]
}
