
data "template_file" "kickstart_template" {
  template = file("${path.module}/img/kickstart-${var.node_type}.ks.tpl")

  vars = {
    maintainer_public_key = trimspace(local_file.public_key.content)
  }
}

resource "local_file" "boot_script" {
  filename = "${path.module}/img/kickstart-${var.node_type}.ks"
  content  = data.template_file.kickstart_template.rendered
}


resource "null_resource" "download_image" {
  count = fileexists("${path.module}/img/cdrom-${var.node_type}.iso") ? 0 : 1
  provisioner "local-exec" {
        command = "curl -fSL ${var.os_url} --parallel --parallel-immediate --parallel-max 20 --progress-bar --retry 20 --output ${path.module}/img/cdrom-${var.node_type}.iso"
        interpreter = ["/bin/sh", "-c"]
  }

  depends_on = [ local_file.boot_script ]
}


resource "null_resource" "build_image" {
 count = var.rebuild_images ? 1 : 0
 provisioner "local-exec" {
      command = <<-EOT
        virt-install --connect ${var.libvirt_uri} --check path_in_use=off --name build-${uuid()} --memory=2048 --vcpus=2 --location ${path.module}/img/cdrom-${var.node_type}.iso --disk "/guest_images/disk-image-${var.node_type}.qcow2,cache=none,size=10,format=qcow2" --network bridge=virbr0 --graphics=none --autoconsole=none --destroy-on-exit --transient --os-variant=${var.os_variant} --initrd-inject ${path.module}/img/kickstart-${var.node_type}.ks --extra-args "inst.ks=file:/kickstart-${var.node_type}.ks inst.memcheck console=tty0 console=ttyS0,115200n8" --wait 30 && chmod 771 /guest_images && chown -R qemu:qemu /guest_images
      EOT
      interpreter = ["/bin/sh", "-c"]
 }
 depends_on = [ null_resource.download_image, local_file.boot_script ]
}

