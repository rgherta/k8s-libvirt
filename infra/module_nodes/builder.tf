resource "null_resource" "build_image" {
  count = var.rebuild_images ? 1 : 0

  
  provisioner "local-exec" {
        working_dir = "${path.module}"
        command = "virt-builder fedora-40 --format qcow2 --arch x86_64 --output ./img/fedora40-${var.node_type}.qcow2 --firstboot ./img/firstboot-${var.node_type}.sh --install=cri-o,cri-tools,crun,crun-vm,kubernetes,qemu-guest-agent,scap-security-guide,lvm2 --root-password password:linux --selinux-relabel"
        environment = {
          # builds with qemu
          LIBGUESTFS_BACKEND = "direct"
        }
  }

  depends_on = [local_file.boot_script]
}



